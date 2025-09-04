#!/usr/bin/env ruby

require "fileutils"
require "json"

LOG_FILEPATH = "~/git/blendergrid-on-rails/.claude/tdd.log"

input = JSON.parse($stdin.read)

# Debug what we got from Claude as input
debug_file = File.new(".claude/hook-input.json", "w")
debug_file.write(input.to_json)
debug_file.close

# Start collecting useful log output in a file we can let Claude read
log_file = File.new(LOG_FILEPATH, "w")

# Check which file was edited
edited_file = input.dig("tool_input", "file_path")
if edited_file.nil?
  puts "No edited file found.."
  exit 2
else
  log_file.write("Edited file: #{edited_file}\n\n")
end

# Run the tests
test_output = `rails test test:system --fail-fast`
so_far_so_good = $?.success?
log_file.write(test_output + "\n\n")
log_file.close

# Report back to Claude
unless so_far_so_good
  prompt = {
    decision: "block",
    reason: "Something is broken. See @#{LOG_FILEPATH} for logs and errors.",
  }
  puts prompt.to_json
end
