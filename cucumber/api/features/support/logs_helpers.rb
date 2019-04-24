# frozen_string_literal: true

# Utility methods for Logs steps
#
require 'open3'

module LogsHelpers
  @@log_location = "/opt/conjur-server/log/development.log"

  def save_amount_of_log_lines(bookmark)
    @bookmarks ||= Hash.new
    @bookmarks[bookmark] = amount_of_log_lines
  end

  def occurences_in_log_filtered_from_bookmark(bookmark, msg)
    raise "Bookmark #{bookmark} doesn't exists" unless @bookmarks[bookmark].present?
    amount = amount_of_log_lines
    raise "Current logs amount is smaller then bookmark '#{bookmark}' value '#{@bookmarks[bookmark]}'" unless amount >= @bookmarks[bookmark]
    occurences_in_log_section(from: @bookmarks[bookmark], to: amount, message: msg)
  end

  private

  def amount_of_log_lines
    wc_cmd = "wc -l #{@@log_location}"
    stdout, stderr, status = Open3.capture3(wc_cmd)
    raise "Failed to run command '#{wc_cmd}' with error '#{stderr}'" unless status.success?
    raise "Log file #{@@log_location} is empty" if stdout.to_s.empty?

    amount = stdout.to_s.split(" ").first().to_i
    raise "Log lines amount '#{amount}' should be a positive number" unless amount > 0
    amount
  end

  def occurences_in_log_section(from:, to:, message:)
    sed_cmd = "sed -n #{from},#{to}p #{@@log_location}"
    stdout, stderr, status = Open3.capture3(sed_cmd)
    raise "Failed to run command '#{sed_cmd}' with error '#{stderr}'" unless status.success?
    stdout.to_s.scan(message).count
  end
end

World(LogsHelpers)
