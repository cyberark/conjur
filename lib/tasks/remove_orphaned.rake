require_relative '../../app/db/preview/roles_without_resources'

namespace :db do
  desc "Preview the role records that will be deleted as part of the db:remove-orphaned task"
  task :"preview-orphaned", [] => [:environment] do
    ::DB::Preview::RolesWithoutResources.new.call
  end

  desc "Remove the orphaned records that are no longer needed"
  task :"remove-orphaned", [] => [:environment] do
    # Query for all roles that were created by policy but have no
    # corresponding resource now, as well as any resources they own.
    latent_item_ids = ::DB::Preview::RolesWithoutResources.new.gather_data

    # Don't do anything if there are no latent roles
    if latent_item_ids.count.zero?
      $stdout.puts("No items to remove")
      next
    end

    $stdout.puts(
      "Deleting #{latent_item_ids.count} " \
      "item#{'s' if latent_item_ids.count > 1} that no longer " \
      "exist#{'s' if latent_item_ids.count == 1} in policy:"
    )

    # Print the ID for deleted items
    latent_item_ids.each do |id|
      $stdout.puts("\t#{id}")

      Role[id]&.delete
      Resource[id]&.delete
    end
  end
end
