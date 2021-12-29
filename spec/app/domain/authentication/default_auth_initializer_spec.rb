# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Default::InitializeDefaultAuth) do
  let(:account) {  "account" }
  let(:service_id) { "test" }
  let(:secret) { double(Secret) }
  def variable_regex(variable_name)
    /#{account}:variable:conjur\/#{auth_name}\/#{service_id}\/#{variable_name}/
  end

  def create_auth_data(auth_name:, json_data:)
    double('AuthData').tap do |data|
      allow(data).to receive(:auth_name).and_return(auth_name)
      allow(data).to receive(:json_data).and_return(json_data)
    end
  end

  subject do
    Authentication::Default::InitializeDefaultAuth.new(
      secret: secret
    ).(
      conjur_account: account,
      service_id: service_id,
      auth_data: auth_data
    )
  end

  context "Given no authenticator data" do
    let(:auth_data) { nil }

    it("doesn't load any secrets") do
      expect(secret).not_to receive(:create)
      expect{ subject }.not_to raise_error
    end
  end

  context "Given valid authenticator data for authn-oidc" do
    let(:auth_name) { "authn-oidc" }
    let(:auth_data) { create_auth_data(auth_name: auth_name, json_data: json_data) }

    context "the json data is nil" do
      let(:json_data) { nil }

      it("doesn't load any secrets") do
        expect(secret).not_to receive(:create)
        expect{ subject }.not_to raise_error
      end
    end

    context "the json data is empty" do
      let(:json_data) { {} }

      it("doesn't load any secrets") do
        expect(secret).not_to receive(:create)
        expect{ subject }.not_to raise_error
      end
    end

    context "the json contains one secret" do
      let(:variable_name) { "test-secret" }
      let(:variable_value) { "SuperSecret" }
      let(:json_data) { {variable_name => variable_value} }

      it("loads the correct secret") do
        expect(secret).to receive(:create).once.with(
          resource_id: variable_regex(variable_name),
          value: variable_value
        )
        expect(subject).to eq(json_data)
      end
    end

    context "the json contains multiple secrets" do
      let(:variable_names) { ["first-secret", "second-secret", "third-secret", "fourth-secret"] }
      let(:variable_values) { ["first", "second", "third", "fourth"] }
      let(:json_data) { Hash[variable_names.zip(variable_values)] }

      it "loads each of the secrets" do
        variable_names.zip(variable_values).each do |name, value|
          expect(secret).to receive(:create).once.with(
            resource_id: variable_regex(name),
            value: value
          )
        end

        expect(subject).to eq(json_data)
      end
    end
  end

end
