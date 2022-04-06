module DB
  module Preview
    class RolesWithoutResources
      def call
        roles = gather_data
        if roles.count > 0
          puts("\nRoles that will be removed because the parent policy has been removed")
          max_id = roles.map { |role| role.identifier }.max_by(&:length).length
          printf("%-#{max_id}s %s\n", "ID", "TYPE")
          roles.sort_by { |role| role.id }.each do |role|
            printf("%-#{max_id}s %s\n", role.identifier, role.kind)
          end
        end
      end

      def gather_data
        Role.
          exclude(role_id: Resource.all.map { |resource| resource.id }).
          where(Sequel.lit('policy_id is not null'))
      end
    end
  end
end