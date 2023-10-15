# frozen_string_literal: true
require 'spec_helper'

shared_context "existing account" do
  let(:validate_account_exists) { double("ValidateAccountExists") }
  before(:each) do
    allow(Authentication::Security::ValidateAccountExists)
      .to receive(:new)
      .and_return(validate_account_exists)
    allow(validate_account_exists).to receive(:call)
      .and_return(true)
  end
end

shared_context "authenticate Basic" do
  let(:params) { { account: account, authenticator: authenticator } }
  let(:basic_auth_header) {
    basic = Base64.strict_encode64([login, basic_password].join(':'))
    "Basic #{basic}"
  }
  let(:request_env) do
    { 'HTTP_AUTHORIZATION' => basic_auth_header }
  end
end

shared_context "invalid authenticate Basic" do
  let(:params) { { account: account, authenticator: authenticator } }
  let(:basic_auth_header) {
    basic = "0g=="
    "Basic #{basic}"
  }
  let(:request_env) do
    { 'HTTP_AUTHORIZATION' => basic_auth_header }
  end
end

shared_context "authenticate user Token" do
  let(:params) { { account: account  } }
  let(:bearer_token) { token_key("rspec", "user").signed_token(login) }
  let(:token_auth_header) do
    "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
  end
  let(:request_env) do
    { 'HTTP_AUTHORIZATION' => token_auth_header }
  end
end

shared_context "create user" do
  def create_user(login)
    id = "rspec:user:#{login}"
    user_role = Role.create(role_id: id).tap do |role|
      options = { role: role }
      options[:password] = password if defined?(password) && password
      Credentials.create(options)
      role.reload
    end
    Resource.create(resource_id: id, owner_id: id).tap do |resource|
      resource.reload
    end

    return user_role
  end

  let(:login) { "default-login" }
  # 'let!' always runs before the example; 'let' is lazily evaluated.
  let!(:the_user) { 
    create_user(login)
  }
  let(:api_key) { the_user.credentials.api_key }
end

shared_context "create host" do
  def create_host(host_login, api_key_annotation=true)
    id = "rspec:host:#{host_login}"
    host_role = Role.create(role_id: id).tap do |role|
      Resource.create(resource_id: id, owner_id: id).tap do |resource|
        # If needed add the annotation to create api key
        add_api_key_annotation(resource, role, api_key_annotation)

        resource.reload
        host_role.reload unless host_role.nil?
      end

      options = { role: role }
      Credentials.create(options)
      role.reload
    end

    return host_role
  end

  let(:host_login) { "default-host-login" }
  let(:host_api_key) { the_host.credentials.api_key }
  let(:host_without_apikey_login) { "host-without-apikey" }
  let!(:host_without_apikey) {
    create_host(host_without_apikey_login, false)
  }
end

shared_context "host authenticate Basic" do
  let(:params) { { account: host_account, authenticator: authenticator } }
  let(:basic_auth_header) {
    basic = Base64.strict_encode64(['host/' + host_login, basic_password].join(':'))
    "Basic #{basic}"
  }
  let(:request_env) do
    { 'HTTP_AUTHORIZATION' => basic_auth_header }
  end
end
