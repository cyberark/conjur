# frozen_string_literal: true

module DB
  module Repository
    module DataObjects
      # DiffElements is an interface providing access to policy diff results,
      # with methods for each of the schema tables.
      # (For the sake of abstraction we're calling them "elements" instead of rows).
      # The write accessors support initialization by the Raw Diff operation and the
      # read accessors are intended for the Mapping operation.
      # It's intended that there be one DTO for each of the diff comparisons, e.g.
      # created_dto, deleted_dto.
      #
      # Background: as originally conceived the attribute methods might
      # have involved non-trivial access because the underlying data type
      # (now hash) wasn't yet decided, thus a class was provided to leave open
      # the possibility of access via methods.  The credentials field may yet
      # require some means of conditional access.
      class DiffElements
        attr_accessor :roles, :resources, :role_memberships, :permissions, :annotations, :credentials
        attr_reader :diff_type

        def initialize(
          diff_type: nil,
          annotations: nil,
          credentials: nil,
          permissions: nil,
          resources: nil,
          role_memberships: nil,
          roles: nil
        )
          @diff_type = diff_type
          @annotations = annotations
          @credentials = credentials
          @permissions = permissions
          @resources = resources
          @role_memberships = role_memberships
          @roles = roles
        end

        # Provide reference to each of the policy tables.
        # The row "elements" are returned as hashes.
        # Note: for security reasons only a subset of columns may be
        # available through the DTO, though none are currently withheld
        def all_elements
          {
            annotations: annotations,
            credentials: credentials,
            permissions: permissions,
            resources: resources,
            role_memberships: role_memberships,
            roles: roles
          }
        end
      end
    end
  end
end
