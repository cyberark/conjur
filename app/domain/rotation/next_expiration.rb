# frozen_string_literal: true

module Rotation

  class NextExpiration
    def initialize(rotated_variable)
      @rotated_variable = rotated_variable
    end

    def after_success
      time_from_now(ttl_in_seconds)
    end

    def after_error
      time_from_now(2/5 * ttl_in_seconds)
    end

    private

    def time_from_now(seconds)
      Time.at(Time.now.to_i + seconds)
    end

    def ttl_in_seconds
      ttl = @rotated_variable.ttl
      ISO8601::Duration.new(ttl).to_seconds
    end
  end

end
