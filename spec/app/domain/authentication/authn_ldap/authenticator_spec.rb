# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnLdap::Authenticator do
  let(:authenticator_instance) do
    Authentication::AuthnLdap::Authenticator.new(env: {})
  end
  
  let(:input) do
    ::Authentication::Strategy::Input.new(
      authenticator_name: 'ldap',
      service_id: 'test',
      account: 'test',
      username: username,
      password: password,
      origin: '127.0.0.1',
      request: nil
    )
  end

  before do
    allow_any_instance_of(Net::LDAP)
      .to receive(:bind_as)
      .and_return(:valid_login?)
  end

  context "as user alice" do
    let(:username) { 'alice'}

    context "with valid non-empty password" do
      let(:valid_login?) { true } 
      let(:password) { 'secret' }

      it "is accepted" do
        expect(authenticator_instance.valid?(input)).to be(true)
      end
    end

    context "with valid empty password" do
      let(:valid_login?) { true } 
      let(:password) { '' }

      it "is rejected" do
        expect(authenticator_instance.valid?(input)).to be(false)
      end
    end
  end

  context "with admin user" do
    let(:valid_login?) { true }
    let(:username) { 'admin' }
    let(:password) { 'my_password' }

    it "is rejected" do
      expect(authenticator_instance.valid?(input)).to be(false)
    end
  end
end
