require "aws-sdk-s3"

# Reconcile stray root-level Active Storage blobs in the S3 bucket.
#
# Legitimate uploads live under "uploads/{upload-uuid}/{filename}" (see the
# upload form's key_prefix/keep_filename options, provided by the vanderoost
# Rails fork). Anything sitting at the *root* of the bucket with a scrambled
# 28-char key is a stock Active Storage blob created without those options —
# historical uploads or abandoned/orphaned direct uploads.
#
# Each root object is classified as:
#   attached   -> blob row exists AND is attached to a record  (KEEP, live file)
#   unattached -> blob row exists but nothing references it     (abandoned upload)
#   untracked  -> no blob row at all                            (orphaned S3 object)
#
#   rake storage:classify        # report only, changes nothing
#   rake storage:cleanup         # dry run: shows what WOULD be removed
#   rake storage:cleanup DRY_RUN=false   # actually purge unattached + untracked
#
# Guards:
#   MIN_AGE_DAYS=2   only touch objects older than this (avoids in-flight uploads)
namespace :storage do
  # Stock Active Storage default keys: a flat base36 token, no slash, no dot.
  AS_KEY_PATTERN = /\A[a-z0-9]{28,}\z/

  desc "Classify root-level Active Storage objects (attached/unattached/untracked)"
  task classify: :environment do
    buckets = StorageOrphans.scan
    StorageOrphans.report(buckets)
  end

  desc "Purge safe root-level orphans (unattached + untracked). DRY_RUN=false to apply"
  task cleanup: :environment do
    dry_run = ENV.fetch("DRY_RUN", "true") != "false"
    buckets = StorageOrphans.scan
    StorageOrphans.report(buckets)
    StorageOrphans.cleanup(buckets, dry_run:)
  end
end

module StorageOrphans
  module_function

  def min_age
    Integer(ENV.fetch("MIN_AGE_DAYS", "2")).days
  end

  def bucket
    @bucket ||= Aws::S3::Resource.new.bucket(
      Rails.configuration.swarm_engine[:bucket]
    )
  end

  # Returns { attached: [...], unattached: [...], untracked: [...], skipped: [...] }
  # Each entry is a small struct-like hash with :key, :size, :age_ok.
  def scan
    unless Rails.application.config.active_storage.service.to_s.start_with?("amazon", "localstack")
      abort "active_storage.service is not S3 in #{Rails.env}; nothing to scan."
    end

    cutoff = min_age.ago
    result = Hash.new { |h, k| h[k] = [] }

    # delimiter "/" returns only root-level objects (keys without a slash),
    # so we never page through the huge uploads/ and projects/ trees.
    bucket.objects(delimiter: "/").each do |obj|
      key = obj.key
      unless key.match?(AS_KEY_PATTERN)
        result[:skipped] << { key:, size: obj.size, age_ok: nil }
        next
      end

      age_ok = obj.last_modified <= cutoff
      blob = ActiveStorage::Blob.find_by(key: key)

      category =
        if blob.nil?             then :untracked
        elsif blob.attachments.exists? then :attached
        else                          :unattached
        end

      result[category] << { key:, size: obj.size, age_ok:, blob: }
    end

    result
  end

  def report(buckets)
    puts "\nBucket: #{Rails.configuration.swarm_engine[:bucket]} " \
         "(env: #{Rails.env})"
    puts "Only objects older than #{min_age.inspect} are cleanup-eligible.\n\n"

    %i[attached unattached untracked skipped].each do |category|
      entries = buckets[category]
      bytes = entries.sum { |e| e[:size] }
      puts format("  %-11s %6d objects  %10s", category, entries.count,
                  human_size(bytes))
    end
    puts
  end

  # Removes unattached blobs (blob.purge -> DB row + S3 object) and untracked
  # S3 objects (direct delete). Never touches attached blobs. Respects MIN_AGE.
  def cleanup(buckets, dry_run:)
    verb = dry_run ? "[dry-run] would remove" : "removing"
    freed = 0
    removed = 0
    skipped_young = 0

    (buckets[:unattached] + buckets[:untracked]).each do |entry|
      unless entry[:age_ok]
        skipped_young += 1
        next
      end

      puts "#{verb} #{entry[:key]} (#{human_size(entry[:size])})"
      freed += entry[:size]
      removed += 1
      next if dry_run

      if entry[:blob]
        entry[:blob].purge
      else
        bucket.object(entry[:key]).delete
      end
    end

    puts "\n#{dry_run ? 'Would free' : 'Freed'} #{human_size(freed)} " \
         "across #{removed} objects."
    puts "Skipped #{skipped_young} objects newer than #{min_age.inspect}." \
      if skipped_young.positive?
    puts "\nDry run — re-run with DRY_RUN=false to apply." if dry_run
  end

  def human_size(bytes)
    ActiveSupport::NumberHelper.number_to_human_size(bytes)
  end
end
