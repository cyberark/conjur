# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::PersistAuth) do

  def create_auth_data(valid:, auth_name:)
    double("AuthData").tap do |data|
      allow(data).to receive(:valid?).and_return(valid)
      allow(data).to receive(:auth_name).and_return(auth_name)

      allow(data).to receive(:errors).and_return(ActiveModel::Errors.new(data))
    end
  end

  context "Given we attempt to initialize a k8s host" do
    let(:account) {  "account" }
    let(:service_id) { "test" }
    let(:resource) { double(Resource) }
    let(:current_user) { "admin" }
    let(:client_ip) { "127.0.0.1" }
    let(:policy_loader) { double('PolicyLoader') }
    let(:auth_initializer) { double('AuthInitializer') }
    let(:auth_name) { "authn-k8s" }
    let(:policy_text) { "test policy text" }
    let(:request_data) { {"some" => "hash data"} }
    let(:auth_data_class) { double(Authentication::AuthnK8s::K8sAuthenticatorData) }
    let(:loaded_policy_result) {
      {
        policy: double('PolicyVersion').tap do |policy|
          allow(policy).to receive_message_chain(:values, :[]).and_return(policy_text)
        end
      }
    }

    subject(:initialize_auth) {
      Authentication::PersistAuth.new(
        logger: Rails.logger,
        auth_initializer: auth_initializer,
        policy_loader: policy_loader,
        auth_data_class: auth_data_class
      ).(
        conjur_account: account,
        service_id: service_id,
        resource: resource,
        current_user: current_user,
        client_ip: client_ip,
        request_data: request_data
      )
    }

    context "we have valid authenticator data" do
      let(:auth_data) { create_auth_data(valid: true, auth_name: auth_name) }

      it("loads the rendered policy") do
        expect(auth_data_class).to receive(:new).with(request_data).and_return(auth_data)

        expect(auth_initializer).to receive(:call).with(
          conjur_account: account,
          service_id: service_id,
          auth_data: auth_data
        )

        expect(policy_loader).to receive(:call).with(
          delete_permitted: false,
          action: :update,
          resource: resource,
          policy_text: policy_text,
          current_user: current_user,
          client_ip: client_ip
        ).and_return(loaded_policy_result)

        expect(ApplicationController.renderer).to receive(:render).with(
          template: "policies/" + auth_name,
          locals: {
            service_id: service_id
          }
        ).and_return(policy_text)

        expect(initialize_auth).to eq(policy_text)
      end
    end

    context "we have invalid authenticator data" do
      let(:auth_data) { create_auth_data(valid: false, auth_name: auth_name) }

      it("does not load the policy") do
        expect(auth_data_class).to receive(:new).with(request_data).and_return(auth_data)

        expect(policy_loader).not_to receive(:call)
        expect{ initialize_auth }.to raise_error(ArgumentError)
      end
    end

  end

end
