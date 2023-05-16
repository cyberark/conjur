# frozen_string_literal: true

# Generates random unique names
#
require 'haikunator'
require 'fileutils'

Before do |scenario|
  @scenario_name = scenario.name
end

Before "@echo" do |scenario|
  @echo = true
end

# Reset the DB between each test
#
# Prior to this hook, our tests had hidden coupling.  This ensures each test is
# run independently.
Before do
  api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
  h = Hash.new
  h['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
  h['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
  h['CONJUR_AUTHN_API_KEY'] = ENV[api_string]

  h.each do |key, value|
    #ENV[key] || ENV[key] = value
    if ENV[key].nil? || ENV[key].empty?
      ENV[key] = value
      puts "#{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
      puts "SET #{key}: #{value}"
    end
  end

  puts "********"
  puts "RUNNING ON PROCESS #{ENV['TEST_ENV_NUMBER']}:"
  puts "CONJUR_URL: #{ENV['CONJUR_APPLIANCE_URL']}"
  puts "DATABASE: #{ENV['DATABASE_URL']}"
  puts "API KEY: #{ENV['CONJUR_AUTHN_API_KEY']}"
  puts "********"
  @user_index = 0

  Role.truncate(cascade: true)
  Secret.truncate
  Credentials.truncate

  Slosilo.each do |k, v|
    unless %w[authn:rspec authn:cucumber].member?(k)
      Slosilo.send(:keystore).adapter.model[k].delete
    end
  end
  
  Account.find_or_create_accounts_resource
  admin_role = Role.create(role_id: "cucumber:user:admin")
  creds = Credentials.new(role: admin_role)
  # TODO: Replace this hack with a refactoring of policy/api/authenticators to share
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
