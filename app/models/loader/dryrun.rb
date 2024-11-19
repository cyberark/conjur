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
      primitive_factory: DataObjects::PrimitiveFactory,
      logger: Rails.logger
    )
      super
      @policy_parse = policy_parse
      @policy_version = policy_version
      @primitive_factory = primitive_factory
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

      if error
        errors = error ? [error.as_validation] : []

        response = {
          status: status,
          errors: errors
        }
      else
        diff_result = map_diffs_to_dtos(
          policy_result.diff,
          policy_result.visible_resources_before,
          policy_result.visible_resources_after
        )
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

    private

    # Maps elements from the Diff Stage to Conjur Resource DTOs.
    # DTOs are defined in the DryRun SD and can transform to Conjur Primitives.
    def map_diffs_to_dtos(diff_dto, visible_resources_before, visible_resources_after)
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

      # The "newest" state of items are censored based on the latest
      # permission set.
      process_actions(diff_dto, visible_resources_after, %i[created final], result)

      # The "older" state of items are censored based on the original
      # permission set.
      process_actions(diff_dto, visible_resources_before, %i[updated deleted], result)

      result
    end

    def process_actions(diff_dto, visible_resources, actions, result)
      primitive_factory = @primitive_factory.new(visible_resources: visible_resources)
      actions.each do |action|
        diff_elements = diff_dto[action].all_elements
    
        # Map Role type rows to items to DTOs
        items = DataObjects::Mapper.map_roles(diff_elements)
        items.each_value do |item|
          dto = primitive_factory.from_hash(hash: item).to_h
          result[action][:items].push(dto)
        end
    
        # Map Resource type rows to items to DTOs
        items = DataObjects::Mapper.map_resources(diff_elements)
        items.each_value do |item|
          dto = primitive_factory.from_hash(hash: item).to_h
          result[action][:items].push(dto)
        end
      end
    end
  end
end
