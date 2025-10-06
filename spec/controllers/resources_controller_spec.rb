# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :truncation

describe ResourcesController, type: :request do

  before do
    # Start fresh
    DatabaseCleaner.clean_with(:truncation)

    # Init Slosilo key
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.create(role_id: 'rspec:user:admin')
  end

  let(:resources_url) do
    '/resources/rspec'
  end

  let(:policies_url) do
    '/policies/rspec/policy/root'
  end

  def list_resources(limit: nil, offset: nil, count: false)
    params = {}
    params.merge!({ :limit => limit }) if limit
    params.merge!({ :offset => offset }) if offset
    params.merge!({ :count => count }) if count
    get(
      resources_url,
      env: token_auth_header(role: current_user),
      params: params
    )
  end

  def count_resources(limit: nil)
    list_resources(limit: limit, count: true)
  end

  def load_variables()
    payload = '[!variable a, !variable b, !variable c, !variable d, !host a, !host b, !host c, !host d, !layer a, !layer b, !layer c]'
    put(
      policies_url,
      env: token_auth_header(role: current_user).merge({ 'RAW_POST_DATA' => payload })
    )
  end

  def retrieve_resource(url, current_user)
    get(
      url,
      env: token_auth_header(role: current_user)
    )
  end

  def apply_root_policy(account, policy_content:, expect_success: false)
    post("/policies/#{account}/policy/root", env: admin_request_env.merge({ 'RAW_POST_DATA' => policy_content }))
    return unless expect_success

    expect(response.code).to eq("201")
  end

  let(:admin_request_env) do
    token = Base64.strict_encode64(Slosilo["authn:rspec"].signed_token("admin").to_json)
    { 'HTTP_AUTHORIZATION' => "Token token=\"#{token}\"" }
  end

  let(:test_policy) do
    <<~POLICY
      - !variable a
      - !policy
        id: conjur/authn-jwt
        owner: !user /admin

      - !policy
        id: conjur/authn-jwt/test-jwt1
        body:
        - !webservice
          annotations:
            test: 123
            other: secret

        - !variable jwks-uri
        - !group users
        - !permit
          role: !group users
          privilege: [ update, authenticate ]
          resource: !webservice

      - !policy
        id: conjur/authn-oidc/keycloak
        body:
        - !webservice
          annotations:
            description: Authentication service for Keycloak, based on Open ID Connect.

        - !variable
          id: provider-uri

        - !group users

        - !permit
          role: !group users
          privilege: [ read, authenticate ]
          resource: !webservice

      - !user alice
      - !user bob

      - !grant
        role: !group conjur/authn-oidc/keycloak/users
        member: !user alice
      - !grant
        role: !group conjur/authn-jwt/test-jwt1/users
        member: !user alice
      - !grant
        role: !group conjur/authn-jwt/test-jwt1/users
        member: !user bob

      - !permit
        role: !user alice
        privilege: [ read ]
        resource: !policy conjur/authn-jwt

    POLICY
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  describe '#index' do

    before(:each) do
      Rails.application.config.conjur_config.api_resource_list_limit_max = 0
      load_variables()
    end

    context 'with default configuration' do
      context 'with no query params defined' do
        context 'user has read permissions' do
          before(:each) do
            list_resources()
            @resources = JSON.parse(response.body)
          end

          it 'should return a 200 status code' do
            expect(response.code).to eq("200")
          end

          it 'should list all resources' do
            expect(@resources.size).to eq(12)
          end

          it 'should order resources alphabetically by resource id' do
            @resources.each_with_index do |resource, idx|
              next if idx == 0
              expect(resource["id"]).to be > @resources[idx-1]["id"]
            end
          end
        end
      end

      context 'with limit query param defined' do
        before(:each) do
          list_resources(limit: 5)
          @resources = JSON.parse(response.body)
        end

        it 'should return a 200 status code' do
          expect(response.code).to eq("200")
        end

        it 'should list resources according to the provided limit' do
          expect(@resources.size).to eq(5)
        end

        it 'should order resources alphabetically by resource id' do
          @resources.each_with_index do |resource, idx|
            next if idx == 0
            expect(resource["id"]).to be > @resources[idx-1]["id"]
          end
        end
      end

      context 'with incorrect limit query param defined' do
        before(:each) do
          list_resources(limit: 'not an integer')
          @resources = JSON.parse(response.body)
        end

        it 'should return a 422 status code' do
          expect(response.code).to eq("422")
        end
      end

      context 'with offset query param defined' do
        before(:each) do
          list_resources(offset: 1)
          @resources = JSON.parse(response.body)
        end

        it 'should return a 200 status code' do
          expect(response.code).to eq("200")
        end

        it 'should offset resources according to the provided offset' do
          list_resources()
          all_resources = JSON.parse(response.body)

          expect(@resources[0]).to eq(all_resources[1])
        end

        it 'should limit list to 10 resources when offset defined and limit not defined' do
          expect(@resources.size).to eq(10)
        end

        it 'should order resources alphabetically by resource id' do
          @resources.each_with_index do |resource, idx|
            next if idx == 0
            expect(resource["id"]).to be > @resources[idx-1]["id"]
          end
        end
      end

      context 'with owner query param defined' do
        before(:each) do
          apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
        end

        context 'owner exists' do
          it 'should return a 200 code' do
            retrieve_resource("/resources/rspec/policy/conjur/authn-jwt?owner=rspec:user:admin", current_user)
            expect(response.code).to eq("200")
          end
        end

        context 'owner does not exist on specified resource' do
          let(:current_user) { Role.find_or_create(role_id: 'rspec:user:bob') }
          it 'should return a 404 code' do
            retrieve_resource("/resources/rspec/policy/conjur/authn-jwt?owner=rspec:user:bob", current_user)
            expect(response.code).to eq("404")
          end
        end
      end
    end

    context 'with custom configuration' do
      it "should list resources according to custom configuration when limit not defined" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        list_resources()
        expect(response.code).to eq("200")
        expect(JSON.parse(response.body).size).to eq(1)
      end

      it "should list resources according to query param limit when custom configuration exceeds limit" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 2
        list_resources(limit: 1)
        expect(response.code).to eq("200")
        expect(JSON.parse(response.body).size).to eq(1)
      end

      it "should throw error when limit exceeds custom configuration" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        list_resources(limit: 2)
        expect(response.code).to eq("422")
      end

      it "should support magic value of 10k limit" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        list_resources(limit: 10000)
        expect(response.code).to eq("200")
      end
    end

    context 'when validating count request' do
      it "should count all resources when custom configuration defined" do
        Rails.application.config.conjur_config.api_resource_list_limit_max = 1
        count_resources()
        expect(response.code).to eq("200")
        expect(response.body).to eq("{\"count\":12}")
      end

      it "should count all resources when custom configuration not defined" do
        count_resources()
        expect(response.code).to eq("200")
        expect(response.body).to eq("{\"count\":12}")
      end

      # There is a currently a bug in the API when supplying both the `limit`
      # and `count` parameters. A count response shouldn't be affected by
      # the `limit` parameter. This should be changed when the bug is fixed (ONYX-22079)
      it "should count resources according to query param limit " do
        count_resources(limit: 1)
        expect(response.body).to eq("{\"count\":1}")
      end
    end
  end

  describe '#show' do
    context 'with valid resource' do
      before(:each) do
        load_variables()
      end

      it 'should return a 200 status code' do
        retrieve_resource('/resources/rspec/variable/a', current_user)
        expect(response.code).to eq("200")
      end

      it 'should return the resource' do
        retrieve_resource('/resources/rspec/variable/a', current_user)
        expect(JSON.parse(response.body)["id"]).to eq("rspec:variable:a")
      end
    end

    context 'with invalid resource' do
      it 'should return a 404 status code' do
        retrieve_resource('/resources/rspec/variable/non-existent-variable', current_user)
        expect(response.code).to eq("404")
      end
    end
  end

  describe '#permitted_roles' do
    context 'user has permissions' do
      before(:each) do
        load_variables()
      end

      context 'permitted roles param is present' do
        it 'should return a 200 status code' do
          retrieve_resource('/resources/rspec/variable/a?permitted_roles=true&privilege=read', current_user)
          expect(response.code).to eq("200")
        end

        it 'should return the roles' do
          retrieve_resource('/resources/rspec/variable/a?permitted_roles=true&privilege=read', current_user)
          expect(JSON.parse(response.body)).to eq(['rspec:user:admin'])
        end
      end

      context 'permitted roles param is not present' do
        it 'should return a 422 status code' do
          retrieve_resource('/resources/rspec/variable/a?permitted_roles=', current_user)
          expect(response.code).to eq("422")
        end

        it 'should raise an argument error' do
          retrieve_resource('/resources/rspec/variable/a?permitted_roles=', current_user)
          expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"privilege" } })
        end
      end

      context 'the specified resource does not exist' do
        it 'should return a 404 status code' do
          retrieve_resource('/resources/rspec/variable/z?permitted_roles=true&privilege=read', current_user)
          expect(response.code).to eq("404")
        end
      end
    end

    context 'user does not have permissions' do
      before(:each) do
        apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
      end

      let(:current_user) { Role.find_or_create(role_id: 'rspec:user:bob') }
      it 'should return a 404 status code' do
        retrieve_resource('/resources/rspec/policy/conjur/authn-jwt?permitted_roles=true&privilege=read', current_user)
        expect(response.code).to eq("404")
      end
    end
  end

  describe '#check_permission' do
    context 'role has specified privilege' do
      before(:each) do
        apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
      end

      it 'should return a 204 status code' do
        retrieve_resource('/resources/rspec/policy/conjur/authn-jwt?check=true&role=rspec:user:alice&privilege=read', current_user)
        expect(response.code).to eq("204")
      end
    end
    context 'role was not found' do
      before(:each) do
        apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
      end

      it 'should return a 403 status code' do
        retrieve_resource('/resources/rspec/policy/conjur/authn-jwt?check=true&role=rspec:user:nonuser&privilege=read', current_user)
        expect(response.code).to eq("403")
      end
    end
    context 'argument error raised' do
      before(:each) do
        apply_root_policy("rspec", policy_content: test_policy, expect_success: true)
      end

      it 'should return a 422 status code' do
        retrieve_resource('/resources/rspec/policy/conjur/authn-jwt?check=1&role=rspec:user:alice', current_user)
        expect(response.code).to eq("422")
        expect(JSON.parse(response.body)).to eq({ "error"=> { "code"=>"argument_error", "message"=>"privilege" } })
      end
    end
  end
end
