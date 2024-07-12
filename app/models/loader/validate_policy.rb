# frozen_string_literal: true
  
# Responsible for validating the business rules of policy that is
# loaded with the CREATE/UPDATE (Modify) operation
# (which do not use custom AuthZ). Called when any policy load
# is called with the ?dryRun=true query parameter. This is designed to
# maintain parity with the existing Loaders.
module Loader
  class ValidatePolicy
    def initialize(loader)
      @loader = loader
    end

    def self.from_policy(policy_version)
      ValidatePolicy.new(Loader::Orchestrate.new(policy_version))
    end

    def call
      # TODO: Implement me. Perform business rules validation.
      true
    end

    def results
      # TODO: Implement me. Return validation results.
      true
    end

    def self.authorize(current_user, resource)
      # No-op.
    end
  end
end
