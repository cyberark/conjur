# frozen_string_literal: true

# Utility methods for Logs steps
#
require 'open3'

module LogsHelpers
  @@log_location = "/src/conjur-server/log/development.log"

  def lines_amount_in_bookmark(bookmark = "bookmark")
    @bookmarks ||= Hash.new
    @bookmarks[bookmark] = amount_of_log_lines
  end

  def occurences_in_log_filtered_from_bookmark(bookmark = "bookmark", msg)
    raise "Bookmark #{bookmark} doesn't exists" unless @bookmarks[bookmark].present?
    amount = amount_of_log_lines
    raise "Current logs lines amount '#{amount}' is smaller then bookmark '#{bookmark}' value '#{@bookmarks[bookmark]}'" unless amount >= @bookmarks[bookmark]
    occurences_in_log_section(from: @bookmarks[bookmark], to: amount, message: msg)
  end

  private

  def amount_of_log_lines
    count_lines_cmd = "wc -l #{@@log_location}"
    stdout, stderr, status = Open3.capture3(count_lines_cmd)
    raise "Command '#{count_lines_cmd}' raised error '#{stderr}'" unless status.success?
    raise "Log file #{@@log_location} is empty" if stdout.to_s.empty?

    amount = stdout.to_s.split(" ").first().to_i
    raise "Log lines amount '#{amount}' should be a positive number" unless amount > 0
    amount
  end

  def occurences_in_log_section(from:, to:, message:)
    filter_log_cmd = "sed -n #{from},#{to}p #{@@log_location}"
    stdout, stderr, status = Open3.capture3(filter_log_cmd)
    raise "Command '#{filter_log_cmd}' raised error '#{stderr}'" unless status.success?
    stdout.to_s.scan(message).count
  end
end

World(LogsHelpers)
