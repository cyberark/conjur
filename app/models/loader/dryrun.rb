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

    # Maps elements from the Diff Stage to Conjur Resource DTOs.
    # DTOs are defined in the DryRun SD and can transform to Conjur Primitives.
    def map_diffs_to_dtos(diff_dto)
      result = {
        created: {
          items: []
        },
        deleted: {
          items: []
        },
        updated: {
          items: []
        },
        final: {
          items: []
        }
      }
      return result if diff_dto.nil?

      actions = %i[created deleted updated final]
      actions.each do |action|
        # Deserialize a set of rows from Diff Stage
        diff_elements = diff_dto[action].all_elements

        # Map Role type rows to items to DTOs
        items = DataObjects::Mapper.map_roles(diff_elements)
        items.values.each do |item|
          dto = DataObjects::DTOFactory.create_DTO_from_hash(item).to_h
          result[action][:items].push(dto)
        end

        # Map Resource type rows to items to DTOs
        items = DataObjects::Mapper.map_resources(diff_elements)
        items.values.each do |item|
          dto = DataObjects::DTOFactory.create_DTO_from_hash(item).to_h
          result[action][:items].push(dto)
        end
      end
      result
    end

    # Returns the syntax / business logic validation report interface
    # (This method will condense once when the feature slices are completed,
    # and several rubocop warnings should vanish.)
    def report(policy_result)
      error = policy_result.error
      status = error ? "Invalid YAML" : "Valid YAML"

      if error
        errors = error ? [error.as_validation] : []

        response = {
          status: status,
          errors: errors
        }
      else
        diff_result = map_diffs_to_dtos(policy_result.diff)
        created = diff_result[:created]
        updated = {
          before: diff_result[:updated],
          after: diff_result[:final]
        }
        deleted = diff_result[:deleted]

        response = {
          status: status,
          created: created,
          updated: updated,
          deleted: deleted
        }
      end
      response
    end
  end
end
