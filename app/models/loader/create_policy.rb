# frozen_string_literal: true

# Responsible for creating policy. Called when a POST request is received
module Loader
  class CreatePolicy
    def initialize(
      loader:,
      logger: Rails.logger
    )
      @loader = loader
      @logger = logger
    end

    def self.from_policy(
      policy_parse,
      policy_version,
      production_class,
      logger: Rails.logger
    )
      CreatePolicy.new(
        loader: production_class.new(
          policy_parse: policy_parse,
          policy_version: policy_version,
          logger: logger
        ),
        logger: logger
      )
    end

    def call_pr(policy_result)
      result = call
      policy_result.created_roles = (result.created_roles)
      policy_result.diff = (result.diff)
    end

    def call
      @loader.snapshot_public_schema_before
      @loader.setup_db_for_new_policy
      @loader.delete_shadowed_and_duplicate_rows
      @loader.store_policy_in_db

      diff

      # Destroy the temp schema used for diffing
      @loader.drop_snapshot_public_schema_before
      @loader.release_db_connection

      PolicyResult.new(
        policy_parse: @loader.policy_parse,
        policy_version: @loader.policy_version,
        created_roles: credential_roles,
        diff: diff
      )
    end

    # This cache needs to be hydrated before the transaction is rolled back
    # and/or before the temp schema is dropped.
    def diff
      @cached_diff ||= @loader.get_diff
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
