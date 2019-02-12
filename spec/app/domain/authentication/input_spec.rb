# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::Input#to_access_request' do
  let (:two_authenticator_env) { "authn-one, authn-two" }

  let (:blank_env) { nil }

  subject do
    Authentication::Input.new(
      authenticator_name: 'authn-test',
      service_id: 'my-service',
      account: 'my-acct',
      username: 'someuser',
      password: 'secret',
      origin: '127.0.0.1',
      request: nil
    )
  end

  context "An ENV lacking CONJUR_AUTHENTICATORS" do
    it "whitelists only the default Conjur authenticator" do
      services = subject.to_access_request(blank_env).whitelisted_webservices
      expect(services.to_a.size).to eq(1)
      expect(services.first.name).to eq(
                                       Authentication::Common.default_authenticator_name
                                     )
    end
  end

  context "An ENV containing CONJUR_AUTHENTICATORS" do
    it "whitelists exactly those authenticators as webservices" do
      services = subject
                   .to_access_request(two_authenticator_env)
                   .whitelisted_webservices
                   .map(&:name)
      expect(services).to eq(['authn-one', 'authn-two'])
    end
  end

  it "passes the username through as the user_id" do
    access_request = subject.to_access_request(blank_env)
    expect(access_request.user_id).to eq(subject.username)
  end

  context "An input with a service_id" do
    it "creates a Webservice with the correct authenticator_name" do
      webservice = subject.to_access_request(blank_env).webservice
      expect(webservice.authenticator_name).to eq(subject.authenticator_name)
    end

    it "creates a Webservice with the correct service_id" do
      webservice = subject.to_access_request(blank_env).webservice
      expect(webservice.service_id).to eq(subject.service_id)
    end

    it "creates a Webservice with the correct account" do
      webservice = subject.to_access_request(blank_env).webservice
      expect(webservice.account).to eq(subject.account)
    end
  end

  context "An input without a service_id" do
    subject do
      Authentication::Input.new(
        authenticator_name: 'authn-test',
        service_id: nil,
        account: 'my-acct',
        username: 'someuser',
        password: 'secret',
        origin: '127.0.0.1',
        request: nil
      )
    end

    it "creates a Webservice without a service_id" do
      webservice = subject.to_access_request(blank_env).webservice
      expect(webservice.service_id).to be_nil
    end
  end
end