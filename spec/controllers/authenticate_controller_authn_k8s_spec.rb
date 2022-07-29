# frozen_string_literal: true

require 'spec_helper'
require 'support/authn_k8s/authn_k8s_test_server'

# Turn on logs to debug
#
# Rails.logger.extend(ActiveSupport::Logger.broadcast(ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))))
# Rails.logger.level = :info
# Audit.logger = Audit::Log::SyslogAdapter.new(
#   Logger.new(STDOUT).tap do |logger|
#     logger.formatter = Logger::Formatter::RFC5424Formatter
#   end
# )

def set_variable_value(account, resource_id, value)
  post("/secrets/#{account}/variable/#{resource_id}", env: admin_request_env.merge({ 'RAW_POST_DATA' => value }))
end

def apply_root_policy(account, policy_content:, expect_success: false)
  post("/policies/#{account}/policy/root", env: admin_request_env.merge({ 'RAW_POST_DATA' => policy_content }))
  if expect_success
    expect(response.code).to eq("201")
  end
end

def define_and_grant_host(account:, host_id:, namespace_annotation:, service_id:)
  host_policy = %Q(
# Define test app host
- !host
  id: #{host_id}
  annotations:
    authn-k8s/authentication-container-name: bash
    #{namespace_annotation}

# Grant app host authentication privileges
- !permit
  role: !host #{host_id}
  privilege: [ read, authenticate ]
  resource: !webservice #{service_id}
  )

  apply_root_policy(account, policy_content: host_policy, expect_success: true)
end

def define_authenticator(account:, service_id:, host_id:)
  # Create authenticator instance by applying policy
  authenticator_policy = %Q(
---
# In the spirit of
# https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Integrations/k8s-ocp/k8s-app-identity.htm?tocpath=Integrations%7COpenShift%252FKubernetes%7CSet%20up%20applications%7C_____4

# Enroll a Kubernetes authentication service
- !policy
  id: #{service_id}
  annotations:
    description: K8s Authenticator policy definitions

  body:
    # Variables for Kubernetes API connection details
    - !variable kubernetes/service-account-token
    - !variable kubernetes/ca-cert
    - !variable kubernetes/api-url

    # Variables for the CA used to sign client certificates
    - !variable ca/cert
    - !variable ca/key

    # Webservice
    - !webservice
      annotations:
        description: Authenticator service for K8s cluster
)

  apply_root_policy(account, policy_content: authenticator_policy, expect_success: true)
end

def initialize_authenticator_ca(account:, service_id:)
  service_resource_id = "#{account}:webservice:#{service_id}"
  # Populate authenticator webservice CA values
  ::Repos::ConjurCA.create(service_resource_id)
end

def configure_k8s_api_access(account:, service_id:, api_url:, ca_cert:, service_account_token:)
  # Populate authenticator configuration variables
  set_variable_value(account, "#{service_id}/kubernetes/api-url", api_url)
  set_variable_value(account, "#{service_id}/kubernetes/ca-cert", ca_cert)
  set_variable_value(account, "#{service_id}/kubernetes/service-account-token", service_account_token)
end

# fake_authn_k8s_login returns a signed certificate based on the input CSR. It is "fake" because it mimicks the expected behavior of the server without the need
# for a request roundtrip.
def fake_authn_k8s_login(account, service_id, host_id:)
  service_resource_id = "#{account}:webservice:#{service_id}"

  hostpkey = OpenSSL::PKey::RSA.new(2048)
  alt_names = [
    "URI:spiffe://cluster.local/namespace/default/pod/bash-8449b79d7-c2fwd"
  ]
  smart_csr = Util::OpenSsl::X509::SmartCsr.new(
    Util::OpenSsl::X509::QuickCsr.new(common_name: "host.#{host_id}", rsa_key: hostpkey, alt_names: alt_names).request
  )

  Repos::ConjurCA.ca(service_resource_id).signed_cert(
    smart_csr,
    subject_altnames: alt_names
  )
end

def authn_k8s_login(authenticator_id:, host_id:)
  # Fake login
  hostpkey = OpenSSL::PKey::RSA.new(2048)
  alt_names = [
    "URI:spiffe://cluster.local/namespace/default/pod/bash-8449b79d7-c2fwd"
  ]
  smart_csr = Util::OpenSsl::X509::SmartCsr.new(
    Util::OpenSsl::X509::QuickCsr.new(common_name: "#{host_id}", rsa_key: hostpkey, alt_names: alt_names).request
  )

  payload = {
    'HTTP_HOST_ID_PREFIX' => 'host',
    'RAW_POST_DATA' => smart_csr.to_s,
  }
  post("/#{authenticator_id}/inject_client_cert", env: payload)
end

def authn_k8s_authenticate(authenticator_id:, account:, host_id:, signed_cert_pem:)
  payload = {
    'HTTP_X_SSL_CLIENT_CERTIFICATE' => CGI.escape(signed_cert_pem)
  }
  escaped_host_id = CGI.escape("host/#{host_id}")
  post("/#{authenticator_id}/#{account}/#{escaped_host_id}/authenticate", env: payload)
end

describe AuthenticateController, :type => :request do
  # Test server is defined in the appropritate "around" hook for the test example
  let(:test_server) { @test_server }

  before(:all) do
    # Start fresh
    DatabaseCleaner.clean_with(:truncation)

    # Init Slosilo key
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.create(role_id: 'rspec:user:admin')
  end

  describe "#authenticate" do
    context "k8s api access contains subpath" do

      around(:each) do |example|
        WebMock.disable_net_connect!(allow: 'http://localhost:1234')
        AuthnK8sTestServer.run_async(
          subpath: "/some/path",
          bearer_token: "bearer token"
        ) do |test_server|
          @test_server = test_server
          example.run(test_server)
        end
      end

      before(:each) do
        # Setup authenticator
        define_authenticator(
          account: account,
          service_id: service_id,
          host_id: test_app_host
        )
        initialize_authenticator_ca(
          account: account,
          service_id: service_id
        )
        configure_k8s_api_access(
          account: account,
          service_id: service_id,
          api_url: "http://localhost:1234/some/path",
          ca_cert: "---",
          service_account_token: "bearer token"
        )
        # ensure authenticator is enabled. Unfortunately there's no nicer way to do this since configuration used is that which is evaluated at load time!
        allow_any_instance_of(Authentication::Webservices).to receive(:include?).and_return(true)
      end

      let(:account) { "rspec" }
      let(:authenticator_id) { "authn-k8s/meow" }
      let(:service_id) { "conjur/#{authenticator_id}" }
      let(:test_app_host) { "h-#{random_hex}" }
      # Allows API calls to be made as the admin user
      let(:admin_request_env) do
        { 'HTTP_AUTHORIZATION' => "Token token=\"#{Base64.strict_encode64(Slosilo["authn:rspec"].signed_token("admin").to_json)}\"" }
      end

      let(:namespace_name_annot) { 'authn-k8s/namespace: default' }
      let(:namespace_label_annot) { 'authn-k8s/namespace-label: "field.cattle.io/projectId=p-q7s7z"' }

      it "client successfully authenticates with namespace name restriction" do
        define_and_grant_host(
          account: account,
          host_id: test_app_host,
          namespace_annotation: namespace_name_annot,
          service_id: service_id
        )

        # NOTE: option to do an in-memory fake login request
        # signed_cert = fake_authn_k8s_login(account, service_id, host_id: test_app_host)

        # Login request, grab the signed certificate from the fake server
        authn_k8s_login(
          authenticator_id: authenticator_id,
          host_id: test_app_host
        )
        signed_cert = test_server.copied_content

        # Authenticate request
        authn_k8s_authenticate(
          authenticator_id: authenticator_id,
          account: account,
          host_id: test_app_host,
          signed_cert_pem: signed_cert.to_s
        )

        # Assertions
        expect(response).to be_ok
        token = Slosilo::JWT.parse_json(response.body)
        expect(token.claims['sub']).to eq("host/#{test_app_host}")
        expect(token.signature).to be
        expect(token.claims).to have_key('iat')
      end

      it "client successfully authenticates with namespace label restriction" do
        define_and_grant_host(
          account: account,
          host_id: test_app_host,
          namespace_annotation: namespace_label_annot,
          service_id: service_id
        )

        # NOTE: option to do an in-memory fake login request
        # signed_cert = fake_authn_k8s_login(account, service_id, host_id: test_app_host)

        # Login request, grab the signed certificate from the fake server
        authn_k8s_login(
          authenticator_id: authenticator_id,
          host_id: test_app_host
        )
        signed_cert = test_server.copied_content

        # Authenticate request
        authn_k8s_authenticate(
          authenticator_id: authenticator_id,
          account: account,
          host_id: test_app_host,
          signed_cert_pem: signed_cert.to_s
        )

        # Assertions
        expect(response).to be_ok
        token = Slosilo::JWT.parse_json(response.body)
        expect(token.claims['sub']).to eq("host/#{test_app_host}")
        expect(token.signature).to be
        expect(token.claims).to have_key('iat')
      end
    end

    # TODO: Add more scenarios
    # 1. Kubernetes API errors
    # 2. Conjur Authentication errors
    # ...
  end
end

# bundle exec rspec --format documentation ./spec/controllers/authenticate_controller_authn_k8s_spec.rb
