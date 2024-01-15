# frozen_string_literal: true

require 'spec_helper'

policy_with_no_hosts =
  <<~POLICY
    - !group
      id: Conjur_Cloud_Admins
    - !grant
      role: !group Conjur_Cloud_Admins
      members: 
        - !user /admin
  POLICY

policy_with_hosts =
  <<~POLICY
    - !group
      id: Conjur_Cloud_Admins
    - !group
      id: Conjur_Cloud_Non_Admins
    - !grant
      role: !group Conjur_Cloud_Admins
      members: 
        - !user /admin
    - !host
      owner: !group Conjur_Cloud_Admins
      id: my-host-1
    - !host
      owner: !group Conjur_Cloud_Non_Admins
      id: my-host-2
  POLICY
  
describe LicenseController, type: :request do
  before do
    init_slosilo_keys("rspec")
    StaticAccount.set_account("rspec")
  end

  describe "GET /licenses/conjur" do
    let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
    let(:alice_user) { Role.find_or_create(role_id:  'rspec:user:alice') }

    context "when the user is not in Conjur_Cloud_Admins" do
      it "returns 403" do
        get("/licenses/conjur?language=english",
            env: token_auth_header(role: admin_user))
        assert_response :forbidden
      end
    end

    context "when the user is in Conjur_Cloud_Admins and there are no workloads" do 
      it "returns 200" do 
        put(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            'RAW_POST_DATA' => policy_with_no_hosts
          )
        )
        assert_response :success
        get("/licenses/conjur?language=english",
            env: token_auth_header(role: admin_user))
        assert_response :success
        validate_output(0, response.body)
      end
    end

    context "when the user is in Conjur_Cloud_Admins and there are workloads" do
      it "returns 200" do 
        put(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            'RAW_POST_DATA' => policy_with_hosts
          )
        )
        assert_response :success
        get("/licenses/conjur?language=english",
            env: token_auth_header(role: admin_user))
        assert_response :success
        validate_output(2, response.body)
      end
    end
    context "When the user is not in Conjur_Cloud_Admins and there are workloads" do
      it "returns 403" do

        put(
          '/policies/rspec/policy/root',
          env: token_auth_header(role: admin_user).merge(
            'RAW_POST_DATA' => policy_with_hosts
          )
        )
        assert_response :success
        get("/licenses/conjur?language=english",
            env: token_auth_header(role: alice_user))
        assert_response :forbidden
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
