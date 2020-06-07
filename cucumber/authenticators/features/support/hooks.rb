# frozen_string_literal: true

# Reset the DB between each test
#
# Prior to this hook, our tests had hidden coupling.  This ensures each test is
# run independently.
Before do
  @user_index = 0

  Role.truncate(cascade: true)
  Secret.truncate
  Credentials.truncate

  Slosilo.each do |k, _|
    unless %w(authn:rspec authn:cucumber).member?(k)
      Slosilo.send(:keystore).adapter.model[k].delete
    end
  end
  
  admin_role = Role.create(role_id: "cucumber:user:admin")
  creds = Credentials.new(role: admin_role)
  # TODO: Replace this hack with a refactoring of policy/api/authenticators to
  #       share
  # this code, and to it the api way (probably)
  creds.password = 'SEcret12!!!!'
  creds.save(raise_on_save_failure: true)

  # Save env to revert to it after the test
  @env = {}
  ENV.each do |key, value|
    @env[key] = value
  end
end

After do
  # Revert to original env
  @env.each do |key, value|
    ENV[key] = value
  end
end
