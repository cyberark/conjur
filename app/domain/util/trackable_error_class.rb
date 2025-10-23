# frozen_string_literal: true

# A factory for creating an ErrorClass with an error code prefix
#
module Util
  class TrackableErrorClass
    def self.new(msg:, code:)
      Util::ErrorClass.new("#{code} #{msg}")
    end
  end
end
