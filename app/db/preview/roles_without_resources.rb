module DB
  module Preview
    # Legacy version of RolesWithoutResourcesRecursive mode, for use in
    # db/migrate/20210514185315_role_cascade_delete.rb
    # This only performs a partial cleanup, and is maintained in order to support
    # the old migration that was written before the recursive mode was implemented.
    class RolesWithoutResources
      def call
        roles = gather_data
        if roles.count.positive?
          puts("\nRoles that will be removed because the parent policy has been removed")
          max_id = roles.map(&:identifier).max_by(&:length).length
          printf("%-#{max_id}s %s\n", "ID", "TYPE")
          roles.sort_by(&:id).each do |role|
            printf("%-#{max_id}s %s\n", role.identifier, role.kind)
          end
        else
          printf("\nNo roles to remove\n")
        end
      end

      def gather_data
        Role
          .exclude(role_id: Resource.all.map(&:id))
          .where(Sequel.lit('policy_id is not null'))
      end
    end
  end
end
