# frozen_string_literal: true

# Returns the diff between the current policy and the new policy.
module CommandHandler
  class PolicyDiff
    def initialize(
      policy_repository: DB::Repository::PolicyRepository.new,
      logger: Rails.logger
    )
      @logger = logger
      @policy_repository = policy_repository

      # Defined here for visibility. We shouldn't need to mock these.
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def call(diff_schema_name:)
      @policy_repository.find_created_elements(diff_schema_name: diff_schema_name).bind do |created|
        @policy_repository.find_deleted_elements(diff_schema_name: diff_schema_name).bind do |deleted|
          @policy_repository.find_original_elements(diff_schema_name: diff_schema_name).bind do |original|
            # A hash map of resource_ids used to produce the
            # final diff.
            created_resource_ids = created.resources.each_with_object({}) do |resource, hash|
              hash[resource[:resource_id]] = true
            end
            deleted_resource_ids = deleted.resources.each_with_object({}) do |resource, hash|
              hash[resource[:resource_id]] = true
            end
            updated_resource_ids = original.resources.each_with_object({}) do |resource, hash|
              hash[resource[:resource_id]] = true
            end

            # Derive the final state of the original elements using the
            # created, deleted, and original elements.
            final = find_updated_elements(created, deleted, original, updated_resource_ids)
            final_resource_ids = final.resources.each_with_object({}) do |resource, hash|
              hash[resource[:resource_id]] = true
            end

            # Filter out any duplicates that are present in all three states.
            created.resources = filter_resources(created.resources, created_resource_ids, deleted_resource_ids, updated_resource_ids)
            deleted.resources = filter_resources(deleted.resources, created_resource_ids, deleted_resource_ids, updated_resource_ids)
            original.resources = filter_updated_resources(original.resources, deleted_resource_ids, final_resource_ids)

            return @success.new({
              created: created,
              deleted: deleted,
              updated: original,
              final: final
            })
          end
        end
      end
    end

    private

    # Given diff elements for created, deleted, and updated resources, use
    # them to produce the a diff which contains only elements that can be mapped
    # into the final updated form of the resource.
    def find_updated_elements(created, deleted, updated, updated_resource_ids)
      # Lambda to handling the final result filtering logic.
      # The final attributes are the union of the updated and created attributes
      # (unique), minus any deleted attributes.
      final = lambda do |accessor_method|
        updated_filtered = Set.new(filter_elements(updated.send(accessor_method), updated_resource_ids))
        created_filtered = Set.new(filter_elements(created.send(accessor_method), updated_resource_ids))
        deleted_filtered = Set.new(filter_elements(deleted.send(accessor_method), updated_resource_ids))
        
        created_and_updated = updated_filtered | created_filtered
        (created_and_updated - deleted_filtered).to_a
      end

      DB::Repository::DataObjects::DiffElements.new(
        diff_type: 'final',
        annotations: final.call(:annotations),
        credentials: final.call(:credentials),
        permissions: final.call(:permissions),
        resources: final.call(:resources),
        role_memberships: final.call(:role_memberships),
        roles: final.call(:roles)
      )
    end

    # Returns only elements whose resource_id, role_id, or member_id is in the
    # given hash.
    def filter_elements(elements, hash)
      elements.select do |element|
        hash.include?(element[:resource_id]) ||
          hash.include?(element[:role_id]) ||
          hash.include?(element[:member_id])
      end
    end

    # Remove resources from created/deleted that are
    # that are present in ALL of created/update/deleted hash. Such a
    # resource is "updated" and only appear as such. This prevents
    # duplicates from appearing across these states, and
    # must occur after the final result has been calculated.
    #
    # For example, a duplicate can occur if
    # a row is updated in-place (e.g. ownership of a resource).
    #
    def filter_resources(resources, created_resource_ids, deleted_resource_ids, updated_resource_ids)
      resources.reject do |element|
        created_resource_ids.key?(element[:resource_id]) &&
          deleted_resource_ids.key?(element[:resource_id]) &&
          updated_resource_ids.key?(element[:resource_id])
      end
    end

    # Remove deleted resources from original that are not in the final
    # state.
    #
    # For example, a deleted resource can appear in the original state
    # while it was deleted in the current policy load. When the final
    # state is derived, we know whether or not this resource was in fact
    # deleted or updated.
    #
    def filter_updated_resources(resources, deleted_resource_ids, final_resource_ids)
      resources.reject do |element|
        deleted_resource_ids.key?(element[:resource_id]) &&
          !final_resource_ids.key?(element[:resource_id])
      end
    end
  end
end
