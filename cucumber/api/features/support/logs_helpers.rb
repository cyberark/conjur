# frozen_string_literal: true

# Utility methods for Logs steps
#
# In order to be able to validate messages in the conjur server log,
# we chose to filter the log by save points instead of zeroing out the log,
# due to the following reasons:
# 1. save the log content for troubleshooting
# 2. be able to parallelize the tests in the future
#
module LogsHelpers
  LOG_LOCATION = "/src/conjur-server/log/#{ENV['RAILS_ENV']}.log"

  def num_log_lines
    File.new(LOG_LOCATION).readlines.size
  end

  # NOTE: Client code should explicitly call this to save current log size,
  # rather than making it a side affect of getting the current size
  def save_num_log_lines
    @saved_num_lines = num_log_lines
  end

  def num_matches_since_savepoint(msg)
    cur_num_lines = num_log_lines

    validate_savepoint_exists
    validate_log_didnt_shrink(cur_num_lines)

    start_line = @saved_num_lines
    end_line = cur_num_lines
    File.readlines(LOG_LOCATION)[start_line..end_line].grep(/#{msg}/i).count
  end

  private

  def validate_savepoint_exists
    raise "No savepoint exists.  'save_num_log_lines' must be called before this method" unless @saved_num_lines
  end

  def validate_log_didnt_shrink(cur_num_lines)
    return if cur_num_lines >= @saved_num_lines
    raise "The log has fewer lines (#{cur_num_lines}) than it did before (#{@saved_num_lines})"
  end
end

World(LogsHelpers)
