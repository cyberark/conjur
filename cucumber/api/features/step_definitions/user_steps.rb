# frozen_string_literal: true

When("I am the super-user") do
  @current_user = admin_user
end

When("I am a user named {string}") do |login|
  @current_user = create_user(login, admin_user)
end

Given("I create a new user {string}") do |login|
  create_user login, @current_user || admin_user
end

Given("I have user {string}") do |login|
  unless user_exists?(login)
    create_user login, @current_user || admin_user
  end
end

Given("I have host {string}") do |login|
  unless host_exists?(login)
    create_host login, @current_user || admin_user
  end
end

Given("I create a new admin-owned user {string}") do |login|
  create_user login, admin_user
end

Given('I create a new user {string} in account {string}') do |login, account|
  roleid = "#{account}:user:#{login}"
  Role.create(role_id: roleid)
end

Given("I login as {string}") do |login|
  if host?(login)
    loginid = login.split('/')[1]
    roleid = (login.include?(":") ? login : "cucumber:host:#{loginid}")
  else
    roleid = (login.include?(":") ? login : "cucumber:user:#{login}")
  end

  @current_user = Role.with_pk!(roleid)
  Credentials.new(role: @current_user).save unless @current_user.credentials
end

Given("I log out") do
  @current_user =  nil
  # TODO: investigate smell
  headers.delete(:authorization) if headers.key?(:authorization)
end

Given("I set the password for {string} to {string}") do |login, password|
  # TODO: investigate smell
  if host?(login)
    login_id = login.split('/')[1]
    role = lookup_host(login_id)
  else
    role = lookup_user(login)
  end
  role.password = password
  role.save
end

private

# Determines if login string represents a host, namely prefixed with 'host\'
def self.host?(login)
  login.match? %r{host\/[^:\/]+}
end
