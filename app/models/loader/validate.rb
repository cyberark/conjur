# frozen_string_literal: true

# Loads a policy using the interface of Loader::Orchestrate, but interpreting it
# to produce a YAML validation rather than loading it as working policy.
#
# Producer interfaces determine how a policy is to be produced -- in what way
# it should be rendered. Producers differ from the mode loaders (load, update, replace)
# in that the mode loaders specify how new and pending policies are combined.
# The two designations are somewhat orthogonal, and support, for example, a Dryrun producer
# to operate in the load/update/replace modes.

# Producer classes:
# - Loader::Orchestrate steps through load/update/replace to produce DB results.
# - Loader::DryRun (future) operates like Orchestrate, but doesn't load a working policy,
#   instead producing differences of policies.
# - Loader::Validate produces validation results (but no side effects).

module Loader
  class Validate
    attr_reader :policy_parse, :policy_version, :create_records, :delete_records, :new_roles, :schemata

    def initialize(
      # Validation doesn't use a version, we're just
      # complying with the interpreter signature.
      # Note: the Orchestrator expects version+parse
      # to be DONE already at initialize
      # ...
      policy_parse:,
      policy_version:,
      logger: Rails.logger
    )
      @policy_parse = policy_parse
      @policy_version = policy_version
      @logger = logger
    end

    # Each type of Producer interpreter provides functions to meet
    # the Orchestrate interface used by the loaders.
    # That allows any policy mode Loader to support any Producer.

    # For the Validate interpreter all of these are no-op because we perform no db operations.

    def snapshot_public_schema_before
      # No-op.
    end

    def drop_snapshot_public_schema_before
      # No-op.
    end

    def get_diff
      # No-op.
    end

    def setup_db_for_new_policy
      # No-op
    end

    def delete_removed
      # No-op.
    end

    def delete_shadowed_and_duplicate_rows
      # No-op.
    end

    def upsert_policy_records
      # No-op.
    end

    def store_policy_in_db
      # No-op.
    end

    def clean_db
      # No-op.
    end

    def store_auxiliary_data
      # No-op.
    end

    def release_db_connection
      # No-op.
    end

    def db
      # Sequel::Model.db
    end

    # Roles
    def actor_roles(roles)
      # No-op.
    end

    def credential_roles(actor_roles)
      # No-op.
    end

    # Style this in the "--validate" format
    # What should be the result type?
    # - simply a JSON struct that the controller will render w/o
    #   concern for the content
    # Note: either the provided error already has the enhanced error information,
    #   or alternatively that could be performed here before constructing the response.
    def report(policy_result)
      error = policy_result.error

      if error
        # Construct the message with enhanced error info
        response = {
          "status" => "Invalid YAML",
          "errors" => [
            error.as_validation
          ]
        }
        msg = "Invalid YAML.\n#{error}"

      else
        response = {
          "status" => "Valid YAML",
          "errors" => []
        }
        msg = "Valid YAML"
      end

      @logger.debug(msg)

      response
    end

  end
end
