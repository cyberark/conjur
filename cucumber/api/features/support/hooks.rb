# frozen_string_literal: true

# Generates random unique names
#
require 'haikunator'
require 'fileutils'

# Reset the DB between each test
#
# Prior to this hook, our tests had hidden coupling.  This ensures each test is
# run independently.
Before do
  parallel_cuke_vars = {}
  parallel_cuke_vars['CONJUR_APPLIANCE_URL'] = ENV.fetch('CONJUR_APPLIANCE_URL', "http://conjur#{ENV['TEST_ENV_NUMBER']}")
  parallel_cuke_vars['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
  parallel_cuke_vars['CONJUR_AUTHN_API_KEY'] = ENV["CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"]
  parallel_cuke_vars['AUTHN_LOCAL_SOCKET'] = ENV["AUTHN_LOCAL_SOCKET#{ENV['TEST_ENV_NUMBER']}"]

  parallel_cuke_vars.each do |key, value|
    ENV[key] = value
  end

  @user_index = 0
  @host_index = 0

  Role.truncate(cascade: true)
  Secret.truncate
  Credentials.truncate

  Slosilo.each do |k,v|
    unless %w[authn:rspec authn:cucumber].member?(k)
      Slosilo.send(:keystore).adapter.model[k].delete
    end
  end

  Account.find_or_create_accounts_resource
  admin_role = Role.create(role_id: "cucumber:user:admin")
  Credentials.new(role: admin_role).save(raise_on_save_failure: true)

  # Save env to revert to it after the test
  @env = {}
  ENV.each do |key, value|
    @env[key] = value
  end
end

After do
  FileUtils.remove_dir('cuke_export') if Dir.exist?('cuke_export')

  # Revert to original env
  @env.each do |key, value|
    ENV[key] = value
  end
end

Before("@logged-in") do
  random_login = Haikunator.haikunate
  @current_user = create_user(random_login, admin_user)
end

Before("@logged-in-admin") do
  @current_user = admin_user
end

After('@create_account') do
  system("conjurctl account delete demo")
end
