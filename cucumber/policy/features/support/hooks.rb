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

Before do
  @user_index = 0

  Role.truncate(cascade: true)
  Secret.truncate
  Credentials.truncate

  Slosilo.each do |k, v|
    unless %w(authn:rspec authn:cucumber).member?(k)
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
end
