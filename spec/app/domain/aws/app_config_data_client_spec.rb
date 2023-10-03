# frozen_string_literal: true
require 'spec_helper'

describe Aws::AppConfigDataClient do
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

  subject { Aws::AppConfigDataClient.new }

  context "app config data processing" do
    let(:expected_features) do
      %w[FEATURE1 FEATURE3 FEATURE4 FEATURE7]
    end

    it "extracts the correct features" do
      active_features = subject.send(:extract_active_features, app_config_data, "my_tenant")
      expect(active_features).to eq(expected_features)
    end

    it "returns empty array when json is empty" do
      active_features = subject.send(:extract_active_features, "{}", "my_tenant")
      expect(active_features).to eq([])
    end
  end

end
