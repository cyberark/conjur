# frozen_string_literal: true

require 'spec_helper'

describe Authenticators::Enablement do
  let(:enabled_status){ false }

  let(:subject) do
    Authenticators::Enablement.new(
      enabled: enabled_status
    )
  end

  let(:current_enablment) do
    instance_double(Authentication::UpdateAuthenticatorConfig).tap do |double|
      allow(double).to receive(:call).and_return(nil)
    end
  end

  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')
    Role.find_or_create(role_id: 'rspec:user:owner')
  end

  let(:request) do
    instance_double(ActionDispatch::Request, ip: "127.0.0.1", headers: { "X-Request-ID" => "abc123" })
  end

  describe '#update_enablement_status' do
    before do
      AuthenticatorController::Current.user = Role.find(role_id: 'rspec:user:admin')
      AuthenticatorController::Current.request = request
    end
    context "when the role isnt authorized to update" do
      it "return a not_found failure" do
        allow(Authentication::UpdateAuthenticatorConfig).to receive(:new)
          .and_raise(::Errors::Authentication::Security::WebserviceNotFound.new("test error"))
        res = subject.update_enablement_status(type: "authn-jwt", account: "rspec", service_id: "jwt")
        expect(res.message).to eq("Authenticator: authn-jwt/jwt not found in account 'rspec'")
      end
    end
    context "Valid Request" do
      it "return a not_found failure" do
        allow(Authentication::UpdateAuthenticatorConfig).to receive(:new)
          .and_return(current_enablment)
        res = subject.update_enablement_status(type: "authn-jwt", account: "rspec", service_id: "jwt")
        expect(res.result).to eq(nil)
      end
    end
    context "when the webservice cant be found" do
      it "return a not_found failure" do
        allow(Authentication::UpdateAuthenticatorConfig).to receive(:new)
          .and_raise(Errors::Authentication::Security::RoleNotAuthorizedOnResource.new('rspec:user:admin', :update, "rspec/authn-jwt/jwt"))
        res = subject.update_enablement_status(type: "authn-jwt", account: "rspec", service_id: "jwt")
        expect(res.message).to eq("CONJ00006E 'rspec:user:admin' does not have 'update' privilege on rspec/authn-jwt/jwt")
      end
    end
  end

  describe '#from_input' do
    let(:body) { { enabled: enabled_status } }

    context "with valid body" do
      it "returns an Enablement class" do
        res = Authenticators::Enablement.from_input(body)
        puts res.result
        expect(res.result.instance_of?(Authenticators::Enablement)).to be_truthy
      end
    end
  end

  describe '#parse_input' do
    [
      {
        case: 'when enablement isnt a bool',
        body: { enabled: "test" },
        expected_response: "The enabled parameter must be of type=boolean",
        expected_code: :unprocessable_entity
      },
      {
        case: 'when enablement isnt a in the body',
        body: { config: true },
        expected_response: "Missing required parameter: enabled",
        expected_code: :unprocessable_entity
      },
      {
        case: 'when request body has extra keys',
        body: { config: "test",  enabled: true, name: "test_name" },
        expected_response: "The following parameters were not expected: 'config, name'",
        expected_code: :unprocessable_entity
      }
    ].each do |test_case|
      context test_case[:case].to_s do
        it "returns the response" do
          response = Authenticators::Enablement.parse_input(test_case[:body])
          expect(response.status).to eq(test_case[:expected_code])
          expect(response.message).to eq(test_case[:expected_response])
        end
      end
    end
  end
end
