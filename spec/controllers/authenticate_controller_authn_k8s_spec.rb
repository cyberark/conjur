# frozen_string_literal: true

require 'spec_helper'
require_relative './authn_k8s_test_server'

# Start fresh
# 
DatabaseCleaner.clean_with(:truncation)

# Turn on logs to debug
# 
Rails.logger.extend(ActiveSupport::Logger.broadcast(ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))))
Rails.logger.level = :info
# Audit.logger = Audit::Log::SyslogAdapter.new(
#   Logger.new(STDOUT).tap do |logger|
#     logger.formatter = Logger::Formatter::RFC5424Formatter
#   end
# )

def set_variable_value(resource_id, value)
  post("/secrets/#{account}/variable/#{resource_id}", env: request_env.merge({ 'RAW_POST_DATA' => value }))
end

def apply_root_policy(policy)
  post("/policies/#{account}/policy/root", env: request_env.merge({ 'RAW_POST_DATA' => policy }))
end

def authn_k8s_authenticate(host, client_cert_pem)
  payload = { 
    'HTTP_X_SSL_CLIENT_CERTIFICATE' => CGI.escape(client_cert_pem),
  }
  escaped_host_id = CGI.escape("host/#{host}")
  post("/#{authenticator_id}/#{account}/#{escaped_host_id}/authenticate", env: payload)
end

describe AuthenticateController, :type => :request do
  let(:account) { "rspec" }
  let(:authenticator_id) { "authn-k8s/meow" }
  let(:test_app_host) { "h-#{random_hex}" }

  # Ensure API calls are made by the admin
  let(:login) { "admin" }
  include_context "authenticate Token"

  describe "#authenticate" do
    def invoke()
      service_id = "conjur/#{authenticator_id}"
      webservice_resource_id = "#{account}:webservice:#{service_id}"

      # Ensure authenticator is enabled. Unfortunately there's no nicer way to do this since configuration used is that which is evaluated at load time!
      allow_any_instance_of(Authentication::Webservices).to receive(:include?).and_return(true)

      # Create authenticator instance by applying policy
      authenticator_policy = %Q(
---
# In the spirit of
# https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Integrations/k8s-ocp/k8s-app-identity.htm?tocpath=Integrations%7COpenShift%252FKubernetes%7CSet%20up%20applications%7C_____4

# Define test app host
- !host
  id: #{test_app_host}
  annotations:
    authn-k8s/namespace-label-selector: "field.cattle.io/projectId=p-q7s7z"
    authn-k8s/authentication-container-name: bash
    # authn-k8s/service-account: <service-account>
    # authn-k8s/deployment: <deployment>
    # authn-k8s/deployment-config: <deployment-config>
    # authn-k8s/stateful-set: <stateful-set>

# Enroll a Kubernetes authentication service
- !policy
  id: #{service_id}
  annotations:
    description: K8s Authenticator policy definitions

  body:
  # vars for ocp/k8s api url & access creds
  - !variable kubernetes/service-account-token
  - !variable kubernetes/ca-cert
  - !variable kubernetes/api-url

  # vars for CA for this service ID
  - !variable ca/cert
  - !variable ca/key

  - !webservice
    annotations:
      description: Authenticator service for K8s cluster

  # Grant 'test-app' host authentication privileges
  - !permit
    role: !host /#{test_app_host}
    privilege: [ read, authenticate ]
    resource: !webservice
)
      apply_root_policy(authenticator_policy)
      expect(response.code).to eq("201")

      # Populate authenticator webservice CA values
      ::Repos::ConjurCA.create(webservice_resource_id)
      
      # Populate authenticator configuration variables
      set_variable_value("#{service_id}/kubernetes/api-url", "http://localhost:1234/some/path")
      set_variable_value("#{service_id}/kubernetes/ca-cert", "---")
      set_variable_value("#{service_id}/kubernetes/service-account-token", "sha256~X7FlQf3cQZ7e82rDOHmZGmfyQwMN9JMUyx7RNcfzfUE")

      # Fake login
      hostpkey = OpenSSL::PKey::RSA.new(2048)      
      alt_names = [
        "URI:spiffe://cluster.local/namespace/default/pod/bash-8449b79d7-c2fwd"
      ]
      smart_csr = Util::OpenSsl::X509::SmartCsr.new(
        Util::OpenSsl::X509::QuickCsr.new(common_name: "host.#{test_app_host}", rsa_key: hostpkey, alt_names: alt_names).request
      )
      signed = Repos::ConjurCA.ca(webservice_resource_id).signed_cert(
        smart_csr,
        subject_altnames: alt_names
      )
      
      # Authenticate request
      authn_k8s_authenticate(test_app_host, signed.to_s)
    end
    
    context "with good client options" do
      it "is authorized" do
        server_thread = AuthnK8sTestServer.run_async("/some/path")

        invoke
        expect(response).to be_ok
        token = Slosilo::JWT.parse_json(response.body)
        expect(token.claims['sub']).to eq("host/#{test_app_host}")
        expect(token.signature).to be
        expect(token.claims).to have_key('iat')
      end
    end
  end

  before(:all) do
    # init Slosilo key
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.create(role_id: 'rspec:user:admin')
  end

  after(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end
end

# bundle exec rspec --format documentation ./spec/controllers/authenticate_controller_authn_k8s_spec.rb