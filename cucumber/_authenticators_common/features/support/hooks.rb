# frozen_string_literal: true

Before('@skip') do
  skip_this_scenario
end

# The following is a context object. It allows data to be shared between
# Scenario steps. The use of this context should help reduce the current
# practice of setting and retrieving instance variables in different Scenario
# Steps.

# An example of when a Context might be used is when retriving a user's Conjur
# Authorization Token on one step, and validating the  token on another step.
module Scenario
  class Context
    def initialize(logger: Rails.logger, **kwargs)
      @store = {}
      @logger = logger
      set(**kwargs) if kwargs
    end

    def get(key)
      @store[key]
    end

    def set(**kwargs)
      kwargs.each do |key, value|
        @store[key] = value
      end
    end

    def keys
      @store.keys
    end

    def unset
      @store = {}
    end
  end
end

# Reset the DB between each test
#
# Prior to this hook, our tests had hidden coupling.  This ensures each test is
# run independently.
Before do
  @user_index = 0
  @host_index = 0
  @context = Scenario::Context.new(account: 'cucumber')

  Role.truncate(cascade: true)
  Secret.truncate
  Credentials.truncate

  Slosilo.each do |k, _|
    unless %w[authn:rspec authn:cucumber].member?(k)
      Slosilo.send(:keystore).adapter.model[k].delete
    end
  end

  Account.find_or_create_accounts_resource
  admin_role = Role.create(role_id: "cucumber:user:admin")
  creds = Credentials.new(role: admin_role)
  # TODO: Replace this hack with a refactoring of policy/api/authenticators to
  #       share this code, and to it the api way (probably)
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
  @context.unset
end
