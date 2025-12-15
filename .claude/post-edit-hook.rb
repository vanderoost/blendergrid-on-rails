#!/usr/bin/env ruby

require "pathname"
require "json"

LOG_FILENAME = "claude.log"
DEBUG_LOG_FILENAME = "claude-debug.log"
DEBUG_JSON_FILENAME = "post-edit-hook-input.json"
APP_DIR = Pathname(__dir__).parent
LOG_DIR =  APP_DIR / "log"

log = nil
debug_log = nil
debug_json = nil

begin
  log_filepath = "#{LOG_DIR}/#{LOG_FILENAME}"
  debug_log_filepath = "#{LOG_DIR}/#{DEBUG_LOG_FILENAME}"
  debug_json_filepath = "#{LOG_DIR}/#{DEBUG_JSON_FILENAME}"

  log = File.new(log_filepath, "w")
  debug_log = File.new(debug_log_filepath, "w")
  debug_json = File.new(debug_json_filepath, "w")

  input = JSON.parse($stdin.read)
  debug_json.write(input.to_json)

  edited_file = input.dig("tool_input", "file_path")
  is_success = true
  if edited_file.nil?
    puts "No edited file found.."
    exit 2
  end

  # Get the repository root directory
  repo_root = `git -C #{APP_DIR} rev-parse --show-toplevel 2>/dev/null`.strip
  if repo_root.empty?
    debug_log.write("Not in a git repository, skipping hook\n")
    exit 0
  end

  # Check if edited file is inside the repository
  edited_file_path = Pathname.new(edited_file).realpath.to_s rescue edited_file
  unless edited_file_path.start_with?(repo_root)
    debug_log.write("File #{edited_file} is outside repository, skipping hook\n")
    exit 0
  end

  if true
    debug_log.write("Edited file: #{edited_file}\n\n")

    if File.extname(edited_file) == ".rb"
      rubocop_output = `bundle exec rubocop -a #{edited_file}`
      is_success = $?.success?
      log.write(rubocop_output + "\n\n") if rubocop_output
    end
  end

  if is_success
    test_output = `bin/rails test --fail-fast`
    is_success = $?.success?
    log.write(test_output + "\n\n")
  end

  if is_success
    brakeman_output = `bundle exec brakeman --no-pager --no-color`
    is_success = $?.success?
    log.write(brakeman_output + "\n\n")
  end
ensure
  log&.close
  debug_log&.close
  debug_json&.close
end

unless is_success
  prompt = {
    decision: "block",
    reason: "Something broke. See @#{log_filepath} for details.",
  }
  puts prompt.to_json
end
