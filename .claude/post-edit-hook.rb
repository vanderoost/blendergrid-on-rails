#!/usr/bin/env ruby

require "fileutils"
require "json"

LOG_FILENAME = "post-edit-hook.log"
DEBUG_LOG_FILENAME = "post-edit-hook.debug.log"
DEBUG_JSON_FILENAME = "post-edit-hook.debug.json"
TMP_DIR = "#{ENV["HOME"]}/git/blendergrid-on-rails/.claude/tmp"

log = nil
debug_log = nil
debug_json = nil

begin
  log_filepath = "#{TMP_DIR}/#{LOG_FILENAME}"
  debug_log_filepath = "#{TMP_DIR}/#{DEBUG_LOG_FILENAME}"
  debug_json_filepath = "#{TMP_DIR}/#{DEBUG_JSON_FILENAME}"

  log = File.new(log_filepath, "w")
  debug_log = File.new(debug_log_filepath, "w")
  debug_json = File.new(debug_json_filepath, "w")

  input = JSON.parse($stdin.read)
  debug_json.write(input.to_json)

  edited_file = input.dig("tool_input", "file_path")
  if edited_file.nil?
    puts "No edited file found.."
    exit 2
  else
    debug_log.write("Edited file: #{edited_file}\n\n")
    `rubocop -a #{edited_file}` if File.extname(edited_file) == ".rb"
  end

  test_output = `rails test test:system --fail-fast`
  is_success = $?.success?
  log.write(test_output + "\n\n")

  if is_success
    brakeman_output = `brakeman --no-pager --no-color`
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
    reason: "Something is broken. See @#{log_filepath} for details.",
  }
  puts prompt.to_json
end
