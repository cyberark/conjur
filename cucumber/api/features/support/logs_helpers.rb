# frozen_string_literal: true

# Utility methods for Logs steps
#
require 'open3'

module LogsHelpers
  def save_amount_of_log_lines(bookmark)
    @bookmarks ||= Hash.new
    @bookmarks[bookmark] = amount_of_log_lines
  end

  private

  def amount_of_log_lines
    stdin = "wc -l #{log_location}"
    stdout, stderr, status = Open3.capture3(stdin)
    raise "Failed to run command #{stdin} with error #{stderr}" unless status.success?
    raise "Log file #{log_location} is empty" if stdout.to_s.empty?

    amount = stdout.to_s.split(" ").first().to_i
    raise "Log lines amount '#{amount}' should be a positive number" unless amount > 0
    amount
  end

  def log_location
    "/src/conjur-server/log/development.log"
  end
end

World(LogsHelpers)
