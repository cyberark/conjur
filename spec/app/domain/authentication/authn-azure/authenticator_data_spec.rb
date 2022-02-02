
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnAzure::AzureAuthenticatorData) do
  let(:provider_uri) { "http://provider" }
  let(:id_token_user_property) { "alice" }

  subject do
    Authentication::AuthnAzure::AzureAuthenticatorData.new(json_data)
  end

  
  context "With all JSON parameters present" do
    context "and valid JSON parameters" do
      let(:json_data) { { "provider-uri" => provider_uri } }

      it "is a valid authenticator data object" do
        expect(subject.provider_uri).to eq(provider_uri)
        expect(subject.valid?).to be(true)
      end
    end

    context "With invalid provider uri" do
      let(:provider_uri) { "not a url" }
      let(:json_data) { { "provider-uri" => provider_uri } }

      it "is not a valid authenticator data object" do
        expect(subject.provider_uri).to eq(provider_uri)
        expect(subject.valid?).to be(false)
      end
    end
  end

  context "With missing JSON parameters" do
      let(:json_data) { {} }   

      it "is not a valid authenticator data object and is missing two parameters" do
        expect(subject.provider_uri).to eq(nil)
        expect(subject.valid?).to be(false)
      end
  end

  context "With extra JSON parameters" do
    let(:json_data) { {
      "provider-uri" => provider_uri,
      "extra" => "extra param"
    } }

    it "is not a valid authenticator data object" do
      expect(subject.provider_uri).to eq(provider_uri)
      expect(subject.valid?).to be(false)
    end
  end
end
