# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :truncation

describe AccountsController, type: :request do
  before(:all) do
    # Start fresh
    DatabaseCleaner.clean_with(:truncation)

    # Init Slosilo key
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.create(role_id: '!:!:root')
    Role.create(role_id: 'rspec:user:admin')
    Role['!:!:root'].grant_to(
      Role['rspec:user:admin'],
      admin_option: true
    )
  end

  after(:all) do
    # Remove super user
    DatabaseCleaner.clean_with(:truncation)
  end

  # Allows API calls to be made as the admin user
  let(:admin_request_env) do
    token = Base64.strict_encode64(Slosilo["authn:rspec"].signed_token("admin").to_json)
    { 'HTTP_AUTHORIZATION' => "Token token=\"#{token}\"" }
  end

  def apply_root_policy(account, policy_content:, expect_success: false)
    post("/policies/#{account}/policy/root", env: admin_request_env.merge({ 'RAW_POST_DATA' => policy_content }))
    return unless expect_success

    expect(response.code).to eq("201")
  end

  def retrieve_accounts
    get("/accounts", env: token_auth_header(role: current_user).merge(
      'ACCEPT' => "application/x.secretsmgr.v2beta+json"
    ))
  end

  def create_account
    post(
      "/accounts",
      env: token_auth_header(role: current_user).merge(
        'RAW_POST_DATA' => "id=#{account}",
        'ACCEPT' => "application/x.secretsmgr.v2beta+json",
        'CONTENT_TYPE' => "application/x-www-form-urlencoded"
      )
    )
  end

  def delete_account
    delete(
      "/accounts/rspec", env: token_auth_header(role: current_user).merge(
        'ACCEPT' => "application/x.secretsmgr.v2beta+json"
      )
    )
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:account) { "new-account" }

  describe '#index' do
    context 'show accounts' do
      it 'returns a 200' do
        retrieve_accounts
        expect(response.code).to eq('200')
      end
    end
  end

  describe '#create' do
    context 'user has execute permissions' do
      it 'returns a 201' do
        create_account
        expect(response.code).to eq('201')
      end

      context 'when invalid account name is used' do
        let(:account) { "/new-account" }

        it 'raises an argument error' do
          create_account
          expect(response.code).to eq('422')
          expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"Invalid account: /new-account" } })
        end
      end
    end

    context 'user does not have execute permissions' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }

      it "returns a 403" do
        create_account
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#destroy' do
    context 'user has update permissions' do
      it 'returns a 204' do
        delete_account
        expect(response.code).to eq('204')
      end
    end

    context 'user does not have update permissions' do
      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:alice') }

      it 'returns a 403' do
        delete_account
        expect(response.code).to eq('403')
      end
    end
  end
end
