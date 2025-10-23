module DB
  module Preview
    class CredentialsWithoutRoles
      def call
        credentials = gather_data

        if credentials.count > 0
          puts("\nCredentials that will be removed because the associated role has been removed")
          max_id = credentials.map { |cred| cred.role_id.split(':', 3)[2] }.max_by(&:length).length
          printf("%-#{max_id}s %s\n", "ID", "TYPE")
          credentials.sort_by { |cred| cred.role_id }.each do |cred|
            printf("%-#{max_id}s %s\n", cred.role_id.split(':', 3)[2], cred.role_id.split(':')[1])
          end
        end
      end

      def gather_data
        Credentials.exclude(role_id: Role.all.map { |role| role.id })
      end
    end
  end
end