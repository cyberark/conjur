# frozen_string_literal: true
  
# Responsible for validating the business rules of policy that is
# loaded with the REPLACE operation (which does use custom AuthZ). Called when
# any policy load is called with the ?dryRun=true query parameter. This is
# designed to maintain parity with
# the existing Loaders.
module Loader
  class ValidateReplacePolicy
    def initialize(loader)
      @loader = loader
    end

    def self.from_policy(policy_version)
      ValidateReplacePolicy.new(Loader::Orchestrate.new(policy_version))
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
      return if current_user.policy_permissions?(resource, 'update')

      Rails.logger.info(
        Errors::Authentication::Security::RoleNotAuthorizedOnPolicyDescendants.new(
          current_user.role_id,
          'update',
          resource.resource_id
        )
      )
      raise ApplicationController::Forbidden
    end
  end
end
