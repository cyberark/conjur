# frozen_string_literal: true

# Generates random unique names
#
require 'haikunator'

Before do
  @user_index = 0

  Role.truncate(cascade: true)
  Secret.truncate
  Credentials.truncate

  Slosilo.each do |k,v|
    unless %w(authn:rspec authn:cucumber).member?(k)
      Slosilo.send(:keystore).adapter.model[k].delete
    end
  end
  
  Account.find_or_create_accounts_resource
  admin_role = Role.create(role_id: "cucumber:user:admin")
  Credentials.new(role: admin_role).save(raise_on_save_failure: true)
end

Before("@logged-in") do
  random_login = Haikunator.haikunate
  @current_user = create_user(random_login, admin_user)
end

Before("@logged-in-admin") do
  @current_user = admin_user
end
