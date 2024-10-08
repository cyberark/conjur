# frozen_string_literal: true

module Loader
  # DryRun loads a policy using the interface of Loader::Orchestrate,
  # but interpreting it to produce a dry-run simulation of what the
  # resulting policy would be.
  #
  class DryRun < Orchestrate
    def initialize(
      policy_parse:,
      policy_version:,
      logger: Rails.logger
    )
      super
      @policy_parse = policy_parse
      @policy_version = policy_version
      @logger = logger
    end

    # TODO: this responsibility can be moved into the PolicyRepository as part
    # of CNJR-6965.
    #
    # Create a unique name for the "before" schema
    # ("before" meaning, before application of the dry-run policy)
    #
    # (The .first method is NOT wanted, and breaks the function)
    # rubocop:disable Style/UnpackFirst
    def diff_schema_name
      @random ||= Random.new
      rnd = @random.bytes(8).unpack('h*').first
      @diff_schema_name ||= "policy_loader_before_#{rnd}"
    end
    # rubocop:enable Style/UnpackFirst

    # Returns the syntax / business logic validation report interface
    # (This method will condense once when the feature slices are completed,
    # and several rubocop warnings should vanish.)
    def report(policy_result)
      error = policy_result.error
      status = error ? "Invalid YAML" : "Valid YAML"
      # Includes enhanced error info
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
        "after" => final
      }
      deleted = {
        "items" => items.length ? items : []
      }

      if error
        {
          "status" => status,
          "errors" => errors
        }
      else
        {
          "status" => status,
          "created" => created,
          "updated" => updated,
          "deleted" => deleted
        }
      end
    end
  end
end
