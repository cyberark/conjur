# frozen_string_literal: true

require_relative 'error_class'

# A factory for creating an ErrorClass with an error code prefix
#
module Util
  class TrackableErrorClass
    def self.new(msg:, code:)
      ErrorClass.new("#{code} #{msg}")
    end
  end
end
