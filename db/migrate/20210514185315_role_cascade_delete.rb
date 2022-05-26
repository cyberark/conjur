# This migration performs the following actions
#
# - It deletes any existing credentials for roles that no longer exist. This
#   removes latent credentials that should no longer exist and prepares the
#   database for adding a cascade delete to automatically delete them in the
#   future when roles are deleted.
#
# - It adds a cascade delete between Credentials and Roles based on role_id.
#   This causes the credentials record to be deleted automatically when the
#   role is deleted.
#
# - It deletes roles that were created by loading policy, but for which there
#   is no longer a policy resource in the database. This cleans up latent
#   roles that should no longer exists.
#
# NOTE: We cannot add a cascade delete relationship between Roles and Resources
#       because there are some roles that intentionally do not have a resource
#       record in the database because they are not created by policy. These
#       are the root admin `!:!:root` and each account admin
#       (e.g. `{acount}:user:admin`). Preventing future latent roles is
#       handled by improvements to the policy load orchestration to ensure role
#       records are removed when the resource record is removed.

Dir[File.dirname(__FILE__) + '/../../app/db/preview/*.rb'].each do |file|
  require file
end

Sequel.migration do
  up do
    def delete_latent_credentials
      # Query for all credentials that have no corresponding role
      latent_credentials = ::DB::Preview::CredentialsWithoutRoles.new.gather_data

      # Don't do anything if there are no latent credentials
      return if latent_credentials.count.zero?
  
      $stderr.puts(
        "Deleting #{latent_credentials.count} " \
        "credential#{'s' if latent_credentials.count > 1} for roles that "\
        "no longer exist:"
      )
  
      # Print the role ID for deleted credentials
      latent_credentials.each do |credential|
        $stderr.puts("\t#{credential.role_id}")

        credential.delete
      end
    end

    def add_credentials_cascade_delete
      # Create cascade delete relationship between role and credentials so when
      # a role is deleted its credentials are deleted too
      alter_table(:credentials) do
        add_foreign_key([:role_id], :roles, on_delete: :cascade)
      end
    end
  
    def delete_latent_roles
      # Query for all roles that were created by policy but have no
      # corresponding resource now.
      latent_roles = ::DB::Preview::RolesWithoutResources.new.gather_data
  
      # Don't do anything if there are no latent roles
      return if latent_roles.count.zero?
  
      $stderr.puts(
        "Deleting #{latent_roles.count} " \
        "role#{'s' if latent_roles.count > 1} that no longer " \
        "exist#{'s' if latent_roles.count == 1} in policy:"
      )
  
      # Print the ID for deleted roles
      latent_roles.each do |role|
        $stderr.puts("\t#{role.role_id}")

        role.delete
      end
    end

    delete_latent_credentials

    # We add the cascade delete before deleting latent roles to
    # ensure their credentials will also be deleted.
    add_credentials_cascade_delete

    delete_latent_roles
  end

  down do
    alter_table :credentials do
      drop_foreign_key [:role_id]
    end
  end
end
