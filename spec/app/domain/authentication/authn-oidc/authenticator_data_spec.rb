# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::OidcAuthenticatorData) do
  let(:provider_uri) { "http://provider" }
  let(:id_token_user_property) { "alice" }

  subject do
    Authentication::AuthnOidc::OidcAuthenticatorData.new(json_data)
  end

  context "With all JSON parameters present" do
    let(:json_data) { { "provider-uri" => provider_uri, "id-token-user-property" => id_token_user_property } }
    context "and valid JSON parameters" do
      it "is a valid authenticator data object" do
        expect(subject.provider_uri).to eq(provider_uri)
        expect(subject.id_token_user).to eq(id_token_user_property)
        expect(subject.valid?).to be(true)
      end
    end

    context "and invalid provider uri" do
      let(:provider_uri) { "not a url" }

      it "is not a valid authenticator data object" do
        expect(subject.provider_uri).to eq(provider_uri)
        expect(subject.id_token_user).to eq(id_token_user_property)
        expect(subject.valid?).to be(false)
      end
    end
  end

  context "With missing JSON parameters" do
    context "and only one missing parameter" do
      let(:json_data) { { "provider-uri" => provider_uri } }

      it "is not a valid authenticator data object and is missing a parameter" do
        expect(subject.provider_uri).to eq(provider_uri)
        expect(subject.id_token_user).to eq(nil)
        expect(subject.valid?).to be(false)
      end
    end

    context "and multiple missing parameters" do
      let(:json_data) { {} }   

      it "is not a valid authenticator data object and is missing two parameters" do
        expect(subject.provider_uri).to eq(nil)
        expect(subject.id_token_user).to eq(nil)
        expect(subject.valid?).to be(false)
      end
    end
  end

  context "With extra JSON parameters" do
    let(:json_data) { {
      "provider-uri" => provider_uri,
      "id-token-user-property" => id_token_user_property,
      "extra" => "extra param"
    } }

    it "is not a valid authenticator data object" do
      expect(subject.provider_uri).to eq(provider_uri)
      expect(subject.id_token_user).to eq(id_token_user_property)
      expect(subject.valid?).to be(false)
    end
  end
end
