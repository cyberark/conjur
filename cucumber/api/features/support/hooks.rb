# frozen_string_literal: true

# Generates random unique names
#
require 'haikunator'
require 'fileutils'
require 'cucumber/_common/slosilo_helper'

# Reset the DB between each test
#
# Prior to this hook, our tests had hidden coupling.  This ensures each test is
# run independently.
Before do
  @user_index = 0
  @host_index = 0

  Role.truncate(cascade: true)
  Secret.truncate
  Credentials.truncate

  init_slosilo_keys

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
  FileUtils.remove_dir('cuke_export') if Dir.exists?('cuke_export')

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
