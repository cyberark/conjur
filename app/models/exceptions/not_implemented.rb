# frozen_string_literal: true

module Exceptions
  class NotImplemented < RuntimeError
    attr_reader :message

    def initialize message
      @message = message
    end
  end
end
