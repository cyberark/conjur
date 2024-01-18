# frozen_string_literal: true

require 'spec_helper'

policy_setup =
  <<~POLICY
    - !user
      id: bob
    - !group
      id: Conjur_Cloud_Admins
    - !grant
       role: !group Conjur_Cloud_Admins
       members:
         - !user bob
    - !group
       id: Conjur_Cloud_Users
    - !host
      id: system-host-should-not-be-counted

    - !policy
      id: data 
      owner: !group Conjur_Cloud_Admins
      body:
      - !user
        id: alice 

    - !grant
      role: !group Conjur_Cloud_Users
      members:
        - !user alice@data
  POLICY
  
policy_add_hosts =
  <<~POLICY
    - !host
      owner: !group /Conjur_Cloud_Admins
      id: my-host-1
    - !host
      owner: !group /Conjur_Cloud_Users
      id: my-host-2
  POLICY

describe LicenseController, type: :request do
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  let(:bob_user) { Role.find_or_create(role_id: 'rspec:user:bob') }
  let(:alice_user) { Role.find_or_create(role_id:  'rspec:user:alice') }

  before(:all) do
    init_slosilo_keys("rspec")
    StaticAccount.set_account("rspec")
  end

  before(:each) do
    post(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        'RAW_POST_DATA' => policy_setup
      )
    )
    assert_response :success
  end
  describe "GET /licenses/conjur" do
    context "When the user is not in Conjur_Cloud_Admins" do
      it "returns 403" do
        get("/licenses/conjur?language=english",
            env: token_auth_header(role: alice_user))
        assert_response :forbidden
      end
    end

    context "When the user is in Conjur_Cloud_Admins and there are no workloads" do 
      it "returns 200" do 
        get("/licenses/conjur?language=english",
            env: token_auth_header(role: bob_user))
        assert_response :success
        validate_output(0, response.body)
      end
    end

    context "When the user has invalid token" do
      it "returns 401" do
        get("/licenses/conjur?language=english")
        assert_response :unauthorized
      end
    end

    context "When the langauge is not supported" do
      it "returns 400" do
        get("/licenses/conjur?language=spanish",
            env: token_auth_header(role: bob_user))
        assert_response :bad_request
      end
    end

    context "When the user is in Conjur_Cloud_Admins and there are workloads" do
      before do
        post(
          '/policies/rspec/policy/data',
          env: token_auth_header(role: bob_user).merge(
            'RAW_POST_DATA' => policy_add_hosts
          )
        )
        assert_response :success
      end

      it "returns 200" do 
        get("/licenses/conjur?language=english",
            env: token_auth_header(role: bob_user))
        assert_response :success
        validate_output(2, response.body)
      end
    end
  end
end

def validate_output(count, response_body)
  valid_response =
    <<-RESPONSE 
      {
        "componentName": "Conjur Cloud",
        "optionalSummary": {
          "name": "Workloads",
          "used": "#{count}",
        },
        "licenseData": [
          {
            "licenseSubCategory": "Licenses",
            "licenseElements": [
              {
                "name": "Workloads",
                "used": "#{count}",
              }
            ]
          }
        ]
      }
    RESPONSE
  expect(response_body).to eq(valid_response)
end
