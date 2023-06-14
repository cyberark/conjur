
# Slosilo key id changed from authn:account:host/user to authn:account:host/user:current/previous
# This migration should run only in existing tenants that include authn:account:host/user keys

Sequel.migration do
  up do
    # update only if 'authn:conjur:host' or 'authn:conjur:user' accounts exists
    if Slosilo['authn:conjur:host'] || Slosilo['authn:conjur:user']
      Rake::Task['slosilo:generate'].execute(name: 'authn:conjur:host:current')
      Rake::Task['slosilo:generate'].execute(name: 'authn:conjur:user:current')
      run("DELETE FROM slosilo_keystore WHERE (id = 'authn:conjur:host');")
      run("DELETE FROM slosilo_keystore WHERE (id = 'authn:conjur:user');")
    end
  end
end