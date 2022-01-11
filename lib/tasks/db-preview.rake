require_relative '../../app/db/preview/credentials_without_roles'
require_relative '../../app/db/preview/roles_without_resources'

namespace :db do
  desc "Preview the records that will be deleted as part of the db migration"
  task :"migrate-preview", [] => [:environment] do |t, args|
    ::DB::Preview::RolesWithoutResources.new.call
    ::DB::Preview::CredentialsWithoutRoles.new.call
  end
end