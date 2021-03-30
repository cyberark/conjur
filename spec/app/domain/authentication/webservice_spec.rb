require 'spec_helper'

RSpec.describe(Authentication::Webservice) do
  WS = Authentication::Webservice

  context "A Webservice created from a string" do
    context "with no service id" do
      let(:ws) { WS.from_string('my-account', 'authn-ldap') }

      it "has the correct account" do
        expect(ws.account).to eq('my-account')
      end

      it "has the correct authenticator name" do
        expect(ws.authenticator_name).to eq('authn-ldap')
      end

      it "has the correct service_id" do
        expect(ws.service_id).to be_nil
      end
    end

    context "with no service id containing no slashes" do
      let(:ws) { WS.from_string('my-account', 'authn-ldap/test') }

      it "has the correct account" do
        expect(ws.account).to eq('my-account')
      end

      it "has the correct authenticator name" do
        expect(ws.authenticator_name).to eq('authn-ldap')
      end

      it "has the correct service_id" do
        expect(ws.service_id).to eq('test')
      end
    end

    context "with no service id containing slashes" do
      let(:ws) { WS.from_string('my-account', 'authn-ldap/test/subtest') }

      it "has the correct account" do
        expect(ws.account).to eq('my-account')
      end

      it "has the correct authenticator name" do
        expect(ws.authenticator_name).to eq('authn-ldap')
      end

      it "has the correct service_id" do
        expect(ws.service_id).to eq('test/subtest')
      end
    end
  end
end
