require 'spec_helper'

RSpec.describe Authentication::UpdateAuthenticatorConfig do
  include_context "create user"

  let(:account) { "test-account" }
  let(:authenticator) { "authn-test" }
  let(:service_id) { "test-service" }

  let(:resource_id) {
    "#{account}:webservice:conjur/#{authenticator}/#{service_id}"
  }

  let(:webservice_owner) { create_user("webservice-owner") }
  
  let(:current_user) { create_user("current-user") }

  let(:webservice) {
    Resource.create(resource_id: resource_id, owner: webservice_owner)
  }

  let(:read_grant) {
    Permission.create(
      resource: webservice,
      role: current_user,
      privilege: "read"
    )
  }

  let(:write_grant) {
    Permission.create(
      resource: webservice,
      role: current_user,
      privilege: "write"
    )
  }
  
  let(:subject) {
    Authentication::UpdateAuthenticatorConfig.new
  }

  let(:call_params) {
    {
      account: account,
      authenticator: authenticator,
      service_id: service_id,
      enabled: true,
      current_user: current_user
    }
  }

  context "webservice resource exists and the current user has correct permissions" do
    before do
      webservice
      read_grant
      write_grant

      subject.call(call_params)
    end

    it "creates a config record for the resource" do
      config = AuthenticatorConfig.where(resource_id: resource_id).first
      expect(config).to_not be_nil
    end

    it "sets the enabled field correctly" do
      config = AuthenticatorConfig.where(resource_id: resource_id).first
      expect(config.enabled).to eq(true)
    end

    it "updates the enabled field when config already exists" do
      subject.call(call_params.merge(enabled: false))
      config = AuthenticatorConfig.where(resource_id: resource_id).first
      expect(config.enabled).to eq(false)
    end
  end

  context "webservice resource does not exist" do
    it "raises an error" do
      expect { subject.call(call_params) }
        .to raise_error(Exceptions::RecordNotFound)
    end
  end

  context "webservice resource is not visible to the current user" do
    before do
      webservice
    end

    it "raises an error" do
      expect { subject.call(call_params) }
        .to raise_error(Exceptions::RecordNotFound)
    end
  end

  context "webservice resource is not writable by the current user" do
    before do
      webservice
      read_grant
    end
    
    it "raises an error" do
      expect { subject.call(call_params) }.
        to raise_error(ApplicationController::Forbidden)
    end
  end
end
