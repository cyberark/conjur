require 'spec_helper'
require 'conjur/rack'

describe Conjur::Rack do
  describe '.user' do
    include_context "with authorization"
    let(:stubuser) { double :stubuser }
    before do
      allow(Conjur::Rack::User).to receive(:new)
        .with(token, 'someacc', {:privilege => privilege, :remote_ip => remote_ip, :audit_roles => audit_roles, :audit_resources => audit_resources})
        .and_return(stubuser)
    end

    context 'when called in app context' do
      shared_examples_for :returns_user do
        it "returns user built from token" do
          expect(call).to eq stubuser
        end
      end

      include_examples :returns_user

      context 'with X-Conjur-Privilege' do
        let(:privilege) { "elevate" }
        include_examples :returns_user
      end

      context 'with X-Forwarded-For' do
        let(:remote_ip) { "66.0.0.1" }
        include_examples :returns_user
      end

      context 'with Conjur-Audit-Roles' do
        let (:audit_roles) { 'user%3Acook' }
        include_examples :returns_user
      end

      context 'with Conjur-Audit-Resources' do
        let (:audit_resources) { 'food%3Abacon' }
        include_examples :returns_user
      end

    end

    it "raises error if called out of app context" do
      expect { Conjur::Rack.user }.to raise_error('No Conjur identity for current request')
    end
  end
end
