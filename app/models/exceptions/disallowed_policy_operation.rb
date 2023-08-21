# frozen_string_literal: true

module Exceptions
  class DisallowedPolicyOperation < RuntimeError

    def initialize
      super("Updating existing resource disallowed in additive policy operation")
    end

  end
end
