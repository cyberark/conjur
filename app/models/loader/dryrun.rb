# frozen_string_literal: true

# Loads a policy using the interface of Loader::Orchestrate, but interpreting it
# to produce a dry-run simulation of what the resulting policy would be.
#
module Loader
  # Because the DryRun interpreter uses many of the Orchestrate functions it made sense
  # to extend it and add the new DryRun operations.
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
      error = policy_result.error

      if error
        # Construct the message with enhanced error info
        response = {
          "status" => "Invalid YAML",
          "errors" => [
            error.as_validation
          ],
        }
      else
        response = {
          "status" => "Valid YAML",
          "errors" => [],
        }
      end

      msg = error ? "Invalid YAML.\n#{error}" : "Valid YAML"
      @logger.debug(msg)

      response
    end

  end
end
