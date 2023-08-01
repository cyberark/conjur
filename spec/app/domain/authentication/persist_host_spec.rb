# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::PersistAuthHost) do

  def host_data(valid:)
    double('HostDetails').tap do |details|
      allow(details).to receive(:valid?).and_return(valid)
      allow(details).to receive(:id).and_return("test")
      allow(details).to receive(:annotations).and_return({})

      allow(details).to receive(:errors).and_return(ActiveModel::Errors.new(details))
    end
  end

  let(:conjur_account) { "account" }
  let(:service_id) { "test" }
  let(:resource) { double(Resource) }
  let(:current_user) { "admin" }
  let(:client_ip) { "127.0.0.1" }
  let(:policy_loader) { double('PolicyLoader') }
  let(:policy_text) { "test policy text" }
  let(:loaded_policy_result) {
    {
      policy: double('PolicyVersion').tap do |policy|
        allow(policy).to receive_message_chain(:values, :[]).and_return(policy_text)
      end
    }
  }

  context "Given I initialize a k8s host" do
    let(:authenticator) { "authn-k8s" }
    subject(:host_initializer){ Authentication::PersistAuthHost.new(
      logger: Rails.logger, policy_loader: policy_loader
    ).call(
        conjur_account: conjur_account,
        authenticator: authenticator,
        service_id: service_id,
        resource: resource,
        current_user: current_user,
        client_ip: client_ip,
        host_data: host_details
      ) }

    context "with valid host data" do
      let(:host_details) { host_data(valid: true) }

      it "loads the host policy from template" do
        expect(policy_loader).to receive(:call).with(
          delete_permitted: false,
          action: :update,
          resource: resource,
          policy_text: anything,
          current_user: current_user,
          client_ip: client_ip
        ).and_return(
          loaded_policy_result
        )

        ApplicationController.renderer.should_receive(:render).with(
          template: "policies/authn-k8s-host",
          locals: {
            service_id: service_id,
            authenticator: authenticator,
            hosts: [ host_details ]
          }
        )

        expect( host_initializer ).to eq( loaded_policy_result )
      end
    end

    context "with invalid host data" do
      let(:host_details) { host_data(valid: false) }

      it "loads the host policy" do
        expect(policy_loader).not_to receive(:call)
        expect{ host_initializer }.to raise_error(ArgumentError)
      end
    end

  end


end
