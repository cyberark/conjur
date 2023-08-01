# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnGcp::GcpAuthenticatorData) do
  subject do
    Authentication::AuthnGcp::GcpAuthenticatorData.new(json_data)
  end

  
  context "With all JSON parameters present" do
    context "and valid JSON parameters" do
      let(:json_data) { {} }

      it "is a valid authenticator data object" do
        expect(subject.json_data).to eq(json_data)
        expect(subject.valid?).to be(true)
      end
    end
  end

  context "With extra JSON parameters" do
    let(:json_data) { { "extra" => "extra param" } }

    it "is not a valid authenticator data object" do
      expect(subject.json_data).to eq(json_data)
      expect(subject.valid?).to be(false)
    end
  end
end
