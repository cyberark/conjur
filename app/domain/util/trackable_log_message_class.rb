# frozen_string_literal: true

# A factory for creating a LogMessage with a code prefix
#
module Util
  class TrackableLogMessageClass
    def self.new(msg:, code:)
      LogMessageClass.new("#{code} #{msg}")
    end
  end
end
