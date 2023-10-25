# frozen_string_literal: true

require_relative 'error_class'

# A factory for creating an ErrorClass with an error code prefix
#
module Util
  class TrackableErrorClass
    def self.new(msg:, code:, **kwargs) # **kwargs can contain only base_error_class:
      ErrorClass.new("#{code} #{msg}", **kwargs)
    end
  end
end
