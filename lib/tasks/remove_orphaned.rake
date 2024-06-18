require_relative '../../app/db/preview/roles_without_resources'

namespace :db do
  desc "Preview the role records that will be deleted as part of the db:remove-orphaned task"
  task :"preview-orphaned", [] => [:environment] do
    ::DB::Preview::RolesWithoutResources.new.call
  end

  desc "Remove the orphaned role records that are no longer needed"
  task :"remove-orphaned", [] => [:environment] do
    # Query for all roles that were created by policy but have no
    # corresponding resource now.
    latent_roles = ::DB::Preview::RolesWithoutResources.new.gather_data

    # Don't do anything if there are no latent roles
    if latent_roles.count.zero?
      $stderr.puts("No roles to remove")
      exit
    end

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
end
