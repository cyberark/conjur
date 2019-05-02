# frozen_string_literal: true

# A factory for creating an ErrorClass with an error code prefix
#
module Util

  class TrackableErrorClass < ErrorClass
    def self.new(msg:, code:)
      super("#{code} #{msg}")
    end
  end
end
