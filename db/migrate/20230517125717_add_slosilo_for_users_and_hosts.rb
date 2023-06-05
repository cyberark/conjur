require 'rake'
require 'active_record'

# Slosilo key id changed from authn:account to authn:conjur:host / authn:conjur:user
# Two keys (authn:conjur:host and authn:conjur:user) are added to each account upon adding new account
# This migration should run only in existing tenants that include authn:conjur account

Sequel.migration do
  up do
    #update only if 'authn:conjur' account exists
    if Slosilo['authn:conjur']
      Rake::Task['slosilo:generate'].execute(name:'authn:conjur:host')
      Rake::Task['slosilo:generate'].execute(name:'authn:conjur:user')
      run("DELETE FROM slosilo_keystore WHERE (id = 'authn:conjur');")
    end
  end
end
