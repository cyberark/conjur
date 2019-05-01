# frozen_string_literal: true

# Utility methods for Logs steps
#
require 'open3'

module LogsHelpers
  LOG_LOCATION = "/src/conjur-server/log/development.log"

  def lines_amount_in_bookmark(bookmark = "bookmark")
    @bookmarks ||= Hash.new

    lines_cnt = File.new(LOG_LOCATION).readlines.size
    raise "Log lines amount '#{lines_cnt}' should be a positive number" unless lines_cnt > 0

    @bookmarks[bookmark] = lines_cnt
  end

  def occurences_in_log_filtered_from_bookmark(bookmark = "bookmark", msg)
    raise "Bookmark #{bookmark} doesn't exists" unless @bookmarks[bookmark].present?

    lines_cnt = File.new(LOG_LOCATION).readlines.size
    raise "Log lines amount '#{lines_cnt}' should be a positive number" unless lines_cnt > 0
    raise "Current logs lines amount '#{lines_cnt}' is smaller then bookmark '#{bookmark}' value '#{@bookmarks[bookmark]}'" unless lines_cnt >= @bookmarks[bookmark]

    num_lines_matching(start_line: @bookmarks[bookmark], end_line: lines_cnt, text: msg)
  end

  private

  def num_lines_matching(start_line:, end_line:, text:)
    (File.readlines(LOG_LOCATION)[start_line..end_line].grep /#{text}/i).count
  end
end

World(LogsHelpers)
