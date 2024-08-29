# frozen_string_literal: true

# Loads a policy using the interface of Loader::Orchestrate, but interpreting it
# to produce a dry-run simulation of what the resulting policy would be.
#
module Loader
  class DryRun < Orchestrate

    def initialize(
      policy_parse:,
      policy_version:,
      logger: Rails.logger
    )
      super(
        policy_parse:,
        policy_version:,
        logger: Rails.logger
      )
      @policy_parse = policy_parse
      @policy_version = policy_version
      @logger = logger
    end
          
    def get_diff
      # No-op.
      result = {
      }
    end

    def public_schema_before_changes
      # No-op.
    end
  
    def snapshot_public_schema_before
      # No-op.
    end

    def drop_snapshot_public_schema_before
      # No-op.
    end

    # Returns the syntax / business logic validation report interface
    def report(policy_result)

      # Fetch
      error = policy_result.error
      version = policy_result.policy_version
      roles = policy_result.created_roles
      diff = policy_result.diff

      # Hydrate
      # TODO: this presupposes that dry-run diff processing
      # would return results in the created_roles and diff components, and then
      # extraction from those components populates the 'items' array.
      # The actual implementation will be different,
      # and those steps may occur elsewhere.

      status = error ? "Invalid YAML" : "Valid YAML"
      # includes enhanced error info
      errors = error ? [error.as_validation] : []

      items = []

      initial = {
        "items" => items.length ? items : []
      }
      final = {
        "items" => items.length ? items : []
      }

      created = {
        "items" => items.length ? items : []
      }
      updated = {
        "before" => initial,
        "after" => final,
      }
      deleted = {
        "items" => items.length ? items : []
      }

      # API response format follows "Policy Dry Run v2 Solution Design" document
      if error
        response = {
          "status" => status,
          "errors" => errors,
        }
      else
        response = {
          "status" => status,
          "created" => created,
          "updated" => updated,
          "deleted" => deleted,
        }
      end

      response
    end

  end
end
