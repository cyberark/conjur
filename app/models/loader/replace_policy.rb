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
      policy_diff: CommandHandler::PolicyDiff.new,
      policy_repository: DB::Repository::PolicyRepository.new,
      policy_result: ::PolicyResult,
      logger: Rails.logger
    )
      @loader = loader
      @policy_diff = policy_diff
      @policy_repository = policy_repository
      @policy_result = policy_result
      @logger = logger
    end

    def self.from_policy(
      policy_parse,
      policy_version,
      production_class,
      policy_diff: CommandHandler::PolicyDiff.new,
      policy_repository: DB::Repository::PolicyRepository.new,
      policy_result: ::PolicyResult,
      logger: Rails.logger
    )
      ReplacePolicy.new(
        loader: production_class.new(
          policy_parse: policy_parse,
          policy_version: policy_version,
          logger: logger
        ),
        policy_diff: policy_diff,
        policy_repository: policy_repository,
        policy_result: policy_result,
        logger: logger
      )
    end

    def call_pr(policy_result)
      result = call
      policy_result.created_roles = (result.created_roles)
      policy_result.diff = (result.diff)
    end

    # Call sequence that will perform the 'policy replace'
    def call
      # TODO: A refactor is pending for CNJR-6965 to improve testability of the
      # policy loading process. See app/models/loader/create_policy.rb.
      if @loader.diff_schema_name
        @policy_repository.setup_schema_for_dryrun_diff(
          diff_schema_name: @loader.diff_schema_name
        )
      end

      @loader.setup_db_for_new_policy
      @loader.delete_removed
      @loader.delete_shadowed_and_duplicate_rows
      @loader.upsert_policy_records
      @loader.clean_db
      @loader.store_auxiliary_data

      diff = if @loader.diff_schema_name
        @policy_diff.call(
          diff_schema_name: @loader.diff_schema_name
        ).result
      end

      # Destroy the temp schema used for diffing
      if @loader.diff_schema_name
        @policy_repository.drop_diff_schema_for_dryrun(
          diff_schema_name: @loader.diff_schema_name
        )
      end
      @loader.release_db_connection

      @policy_result.new(
        policy_parse: @loader.policy_parse,
        policy_version: @loader.policy_version,
        created_roles: credential_roles,
        diff: diff
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
