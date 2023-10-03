# frozen_string_literal: true
module Util
  #This class is used to cut back server calls by caching the results of a block for a given amount of time.
  class TimeExpiredCache
    def initialize(
      interval= 60,
      &block
    )
      @cached_result = nil
      @result_expires_at = Time.at(0)
      @block = block
      @interval = interval
    end

    def result
      if @cached_result.nil? || @result_expires_at < Time.now
        @cached_result = @block.call
        @result_expires_at = Time.now + @interval
      end
      @cached_result
    end
  end
end
