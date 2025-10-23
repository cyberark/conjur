# frozen_string_literal: true

# Returns the diff between the current policy and the new policy.
module CommandHandler
  class PolicyDiff
    def initialize(
      logger: Rails.logger
    )
      @logger = logger

      # Defined here for visibility. We shouldn't need to mock these.
      @success = Responses::Success
      @failure = Responses::Failure
    end

    def call(created:, deleted:, original:)
      # A hash map of resource_ids used to produce the
      # final diff.
      created_resource_ids = created.resources.each_with_object({}) do |obj, hash|
        hash[obj[:resource_id]] = true
      end
      deleted_resource_ids = deleted.resources.each_with_object({}) do |obj, hash|
        hash[obj[:resource_id]] = true
      end
      updated_resource_ids = original.resources.each_with_object({}) do |obj, hash|
        hash[obj[:resource_id]] = true
      end

      # Derive the final state of the original elements using the
      # created, deleted, and original elements.
      final = find_updated_elements(created, deleted, original, updated_resource_ids)
      final_resource_ids = final.resources.each_with_object({}) do |obj, hash|
        hash[obj[:resource_id]] = true
      end

      # Filter out any duplicates that are present in all three states.
      # This is necessary to prevent duplicates from appearing where they should
      # not when these diff results are mapped later by the DataObjects::Mapper.
      #
      # Note: the resources field is used to derive roles/resources since a
      # role is a resource. Therefore we only need to filter resources.
      # Attributes that are not referenced by a resource are simply ignored by
      # the DataObjects::Mapper. This will save on cpu cycles.
      created.resources = filter_created_or_deleted_resources(created.resources, created_resource_ids, deleted_resource_ids, updated_resource_ids)
      deleted.resources = filter_created_or_deleted_resources(deleted.resources, created_resource_ids, deleted_resource_ids, updated_resource_ids)
      original.resources = filter_original_resources(original.resources, deleted_resource_ids, final_resource_ids)

      @success.new({
        created: created,
        deleted: deleted,
        updated: original,
        final: final
      })
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
        # WARNING: the set does comparisions based on the entire row
        # (hash object) and its contents so if any queries to this data contain
        # different columns, they will appear as distinct elements!
        updated_filtered = Set.new(filter_elements(updated.send(accessor_method), updated_resource_ids))
        created_filtered = Set.new(filter_elements(created.send(accessor_method), updated_resource_ids))
        deleted_filtered = Set.new(filter_elements(deleted.send(accessor_method), updated_resource_ids))

        # Since it is possible for two with the same primary keys but with
        # different fields (columns) to exist across either set. As we're
        # building the final state, we prefer the record from the "created"
        # set over the older value in the "updated" (original) set
        #
        # For example, when an owner_id is updated, the resource appears in
        # these two sets (the resource appears in the "created" set with a new
        # owner_id, and again in the "updated" (original) set with the previous
        # value.
        if accessor_method == :resources
          updated_filtered.reject! do |_updated_hash|
            created_filtered.any? { |created_hash| updated_resource_ids.key?(created_hash[:resource_id]) }
          end
        end

        # TODO: this is how admin remains after an ownership change. It
        # is because her role_membership appears in updated
        created_and_updated = updated_filtered | created_filtered
        (created_and_updated - deleted_filtered).to_a.sort_by do |item|
          %i[resource_id role_id member_id].map { |key| item[key] }
        end
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

    # Remove resources from the list that are present in the created set
    # and also present in either the deleted set or the updated set.
    # Such a resource is considered "updated" and should not appear in only
    # the created/deleted set. This prevents duplicates from appearing across
    # these states.
    #
    # For example, a resource that is created and then immediately updated or
    # deleted should not appear in the returned list as it is considered an
    # update.
    #
    def filter_created_or_deleted_resources(resources, created_resource_ids, deleted_resource_ids, updated_resource_ids)
      resources.reject do |element|
        created_resource_ids.key?(element[:resource_id]) &&
          (deleted_resource_ids.key?(element[:resource_id]) ||
          updated_resource_ids.key?(element[:resource_id]))
      end
    end

    # Remove deleted resources from the original list that are not in the final
    # list.
    #
    # For example, a resource that is marked as deleted but does not appear in
    # the final list should be removed from the original list. This ensures
    # that only resources that are truly deleted or updated are in the
    # returned list.
    #
    def filter_original_resources(resources, deleted_resource_ids, final_resource_ids)
      resources.reject do |element|
        deleted_resource_ids.key?(element[:resource_id]) &&
          !final_resource_ids.key?(element[:resource_id])
      end
    end
  end
end
