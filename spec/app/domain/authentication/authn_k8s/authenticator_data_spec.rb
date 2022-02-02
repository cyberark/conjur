

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnK8s::K8sAuthenticatorData) do
  let(:api_url) { "http://api-gateway" }
  let(:ca_cert) { "-----BEGIN  CERTIFICATE-----\nBASE64ENCODECERT\n----END CERTIFICATE----" }
  let(:service_account_token) { "bob" }

  subject do
    Authentication::AuthnK8s::K8sAuthenticatorData.new(json_data)
  end

  context "With all JSON parameters" do
    let(:json_data) { {
      "api-url" => api_url,
      "ca-cert" => ca_cert,
      "service-account-token" => service_account_token
    } }

    context "With all valid values" do
      it "is a valid authenticator data object" do
        expect(subject.k8s_api_url).to eq(api_url)
        expect(subject.ca_certificate).to eq(ca_cert)
        expect(subject.service_account_token).to eq(service_account_token)
        expect(subject.valid?).to be(true)
      end
    end

    context "With invalid api url" do
      let(:api_url) { "not a url" }

      it "is not a valid authenticator data object" do
        expect(subject.k8s_api_url).to eq(api_url)
        expect(subject.ca_certificate).to eq(ca_cert)
        expect(subject.service_account_token).to eq(service_account_token)
        expect(subject.valid?).to be(false)
      end
    end

    context "With invalid CA certificate" do
      let(:ca_cert) { "badly formatted certificate" }

      it "is not a valid authenticator data object" do
        expect(subject.k8s_api_url).to eq(api_url)
        expect(subject.ca_certificate).to eq(ca_cert)
        expect(subject.service_account_token).to eq(service_account_token)
        expect(subject.valid?).to be(false)
      end
    end
  end

  context "With missing JSON parameters" do
    let(:json_data) { {} }   

    it "is a valid authenticator data object" do
      expect(subject.k8s_api_url).to eq(nil)
      expect(subject.ca_certificate).to eq(nil)
      expect(subject.service_account_token).to eq(nil)
      expect(subject.valid?).to be(true)
    end
  end

  context "With extra JSON parameters" do
    let(:json_data) { {
      "api-url" => api_url,
      "ca-cert" => ca_cert,
      "service-account-token" => service_account_token,
      "extra-param" => "extra"
    } }

    it "is not a valid authenticator data object" do
      expect(subject.k8s_api_url).to eq(api_url)
      expect(subject.ca_certificate).to eq(ca_cert)
      expect(subject.service_account_token).to eq(service_account_token)
      expect(subject.valid?).to be(false)
    end
  end
end
