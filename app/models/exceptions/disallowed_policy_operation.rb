# frozen_string_literal: true

module Exceptions
  class DisallowedPolicyOperation < RuntimeError

    def initialize(context)
      super(self.class.build_message(context))

      @context = context
    end

    class << self
      def build_message(context)
        "WARNING: Updating existing resource disallowed in additive policy operations (POST). " \
        "In a future release, loading this policy file will fail with a 422 error code. " \
        "The following updates have not been applied, and have been discarded: " \
        "#{context.inspect}"
      end
    end
  end
end
