# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnLdap::LdapAuthenticatorData) do
  let(:bind_password) { "some-pass" }
  let(:tls_ca_cert) { "-BEGIN CERTIFICATE-\nSTUF\n-END CERTIFICATE-" }
  let(:annotations) { {"some" => "values"} }

  subject do
    Authentication::AuthnLdap::LdapAuthenticatorData.new(json_data)
  end

  
  context "With all JSON parameters present" do
      let(:json_data) { {
        "bind-password" => bind_password,
        "tls-ca-cert" => tls_ca_cert,
        "annotations" => annotations
      } }
    context "and valid JSON parameters" do
      it "is a valid authenticator data object" do
        expect(subject.bind_password).to eq(bind_password)
        expect(subject.tls_ca_cert).to eq(tls_ca_cert)
        expect(subject.annotations).to eq(annotations)
        expect(subject.valid?).to be(true)
      end
    end

    context "With invalid provider uri" do
      let(:tls_ca_cert) { "bad-cert" }

      it "is not a valid authenticator data object" do
        expect(subject.bind_password).to eq(bind_password)
        expect(subject.tls_ca_cert).to eq(tls_ca_cert)
        expect(subject.annotations).to eq(annotations)
        expect(subject.valid?).to be(false)
      end
    end
  end

  context "With missing JSON parameters" do
      let(:json_data) { {} }   

      it "is not a valid authenticator data object and is missing two parameters" do
        expect(subject.bind_password).to eq(nil)
        expect(subject.tls_ca_cert).to eq(nil)
        expect(subject.annotations).to eq(nil)
        expect(subject.valid?).to be(false)
      end
  end

  context "With extra JSON parameters" do
    let(:json_data) { {
      "bind-password" => bind_password,
      "tls-ca-cert" => tls_ca_cert,
      "annotations" => annotations,
      "extra" => "extra-param"
    } }

    it "is not a valid authenticator data object" do
      expect(subject.bind_password).to eq(bind_password)
      expect(subject.tls_ca_cert).to eq(tls_ca_cert)
      expect(subject.annotations).to eq(annotations)
      expect(subject.valid?).to be(false)
    end
  end
end
