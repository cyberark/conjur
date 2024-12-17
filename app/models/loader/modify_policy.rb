# frozen_string_literal: true

# Responsible for modifying policy. Called when a PATCH request is received
module Loader
  class ModifyPolicy
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
      ModifyPolicy.new(
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

    def call
      @loader.modify_policy(current_user: @current_user)

      @policy_result.new(
        policy_parse: @loader.policy_parse,
        policy_version: @loader.policy_version,
        created_roles: credential_roles,
        diff: @loader.diff,
        visible_resources_before: @loader.visible_resource_hash_before,
        visible_resources_after: @loader.visible_resource_hash_after
      )
    end

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

    def self.authorize(current_user, resource)
      # No-op
    end
  end
end
