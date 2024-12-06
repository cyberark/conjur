# frozen_string_literal: true

# Responsible for replacing policy. Called when a PUT request is received
module Loader
  class ReplacePolicy
    # Creates a <mode>Policy instance.
    # The loader is an instance of Policy Producer, initialized with a processed policy.
    # By using Producer methods (e.g. new_roles, report) the policy can be processed
    # in a way specific to Production type (Orchestrate, Validate, etc.)

    def initialize(
      loader:,
      current_user:,
      policy_result: ::PolicyResult,
      resource: ::Resource,
      logger: Rails.logger
    )
      @loader = loader
      @current_user = current_user
      @policy_result = policy_result
      @resource = resource
      @logger = logger
    end

    def self.from_policy(
      policy_parse,
      policy_version,
      production_class,
      current_user,
      policy_result: ::PolicyResult,
      resource: ::Resource,
      logger: Rails.logger
    )
      ReplacePolicy.new(
        loader: production_class.new(
          policy_parse: policy_parse,
          policy_version: policy_version,
          logger: logger
        ),
        policy_result: policy_result,
        current_user: current_user,
        resource: resource,
        logger: logger
      )
    end

    def call_pr(policy_result)
      result = call
      policy_result.created_roles = (result.created_roles)
      policy_result.diff = (result.diff)
      policy_result.visible_resources_before = (result.visible_resources_before)
      policy_result.visible_resources_after = (result.visible_resources_after)
    end

    # Call sequence that will perform the 'policy replace'
    def call
      @loader.replace_policy(current_user: @current_user)

      @policy_result.new(
        policy_parse: @loader.policy_parse,
        policy_version: @loader.policy_version,
        created_roles: credential_roles,
        diff: @loader.diff,
        visible_resources_before: @loader.visible_resource_hash_before,
        visible_resources_after: @loader.visible_resource_hash_after
      )
    end

    # The ones resulting from 'call'
    def new_roles
      @loader.new_roles
    end

    def credential_roles
      actor_roles = @loader.actor_roles(new_roles)
      @loader.credential_roles(actor_roles)
    end

    def report(policy_result)
      @loader.report(policy_result)
    end

    def self.authorize(
      current_user,
      resource,
      logger: Rails.logger
    )
      return if current_user.policy_permissions?(resource, 'update')

      logger.info(
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
