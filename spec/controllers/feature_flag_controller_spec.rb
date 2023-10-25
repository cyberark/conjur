# frozen_string_literal: true

require 'spec_helper'

describe FeatureFlagController, type: :request do
  let(:app_config_data) do
    """
    {
      \"FEATURE1\": \"ALWAYS_ON\",
      \"FEATURE2\": \"ALWAYS_OFF\",
      \"FEATURE3\": \"ALWAYS_ON\",
      \"FEATURE4\": {\"ON_ONLY_FOR_SPECIFIC_TENANTS\" : [\"my_tenant\"]},
      \"FEATURE5\": {\"ON_ONLY_FOR_SPECIFIC_TENANTS\" : [\"other_tenant\"]},
      \"FEATURE6\": {\"OFF_ONLY_FOR_SPECIFIC_TENANTS\" : [\"my_tenant\"]},
      \"FEATURE7\": {\"OFF_ONLY_FOR_SPECIFIC_TENANTS\" : [\"other_tenant\"]}
    }
    """
  end

  subject {FeatureFlagController.new}

  describe "/features endpoint" do
    let(:account) { "rspec" }
    before do
      init_slosilo_keys(account)
      @current_user = Role.find_or_create(role_id: "#{account}:user:alice")
    end

    context "endpoint returns expected responses" do
      before(:each) do
        allow_any_instance_of(Conjur::ConjurConfig).to receive(:tenant_name).and_return("my_tenant")
      end
      after(:each) do
        subject.send(:purge_result)
      end
      it "returns 200" do
        allow_any_instance_of(Aws::AppConfigDataClient).to receive(:pull_from_app_config).and_return(app_config_data)
        get("/features", env: token_auth_header(role: @current_user, is_user: true))
        expect(response.code).to eq("200")
        resp = JSON.parse(response.body)
        expect(resp).to eq({"featureFlags" => %w[FEATURE1 FEATURE3 FEATURE4 FEATURE7]})
      end

      it "app config is invoked once despite multiple calls" do
        expect_any_instance_of(Aws::AppConfigDataClient).to receive(:pull_from_app_config).once.and_return(app_config_data)
        get("/features", env: token_auth_header(role: @current_user, is_user: true))
        get("/features", env: token_auth_header(role: @current_user, is_user: true))
      end

      it "returns 422 when app config data is invalid" do
        allow_any_instance_of(Aws::AppConfigDataClient).to receive(:pull_from_app_config).and_return("invalid json")
        get("/features", env: token_auth_header(role: @current_user, is_user: true))
        expect(response.code).to eq("422")
      end
    end
  end
end
