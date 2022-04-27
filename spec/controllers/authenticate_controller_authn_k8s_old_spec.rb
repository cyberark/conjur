# frozen_string_literal: true

require 'spec_helper'
require_relative './authn_k8s_test_server'

def gen_authn(account, service_id, host, api_url, ca_cert, sa_token)
  webservice_resource_id = "#{account}:webservice:#{service_id}"

  # Create role and resource for webservice
  webservice_role = Role.create(role_id: webservice_resource_id).tap do |role|
    options = { role: role }
    Credentials.create(options)
    role.reload
  end
  webservice_resource = Resource.create(resource_id: webservice_resource_id, owner_id: webservice_resource_id).tap do |resource|
    resource.reload
    webservice_role.reload
  end
  # Create grant for webservice
  webservice_resource.permit("authenticate", the_host)

  role_id = "#{account}:policy:#{service_id}"
  Role.create(role_id: role_id)
  Resource.create(
    resource_id: "#{account}:variable:#{service_id}/ca/cert",
    owner_id: role_id
  )
  Resource.create(
    resource_id: "#{account}:variable:#{service_id}/ca/key",
    owner_id: role_id
  )
  create_secret("#{account}:variable:#{service_id}/kubernetes/api-url", role_id, api_url)
  create_secret("#{account}:variable:#{service_id}/kubernetes/ca-cert", role_id, ca_cert)
  create_secret("#{account}:variable:#{service_id}/kubernetes/service-account-token", role_id, sa_token)
  

  ::Repos::ConjurCA.create(webservice_resource_id)
end

def create_secret(resource_id, owner_id, value)
  resource = Resource.create(
    resource_id: resource_id,
    owner_id: owner_id
  )
  Secret.create(resource: resource, value: value)
end

def set_secret(resource_id, value)
  Secret.create(resource_id: resource_id, value: value)
end

DatabaseCleaner.clean_with(:truncation)
describe AuthenticateController, :type => :request do
  include_context "existing account"
  include_context "authenticate Token"
  let(:policies_url) do
    # From config/routes.rb:
    # "/policies/:account/:kind/*identifier"
    '/policies/rspec/policy/root'
  end

  let(:admin) { Role.find(role_id: 'rspec:user:admin') }

  let(:host_login) { "h-#{random_hex}" }
  let(:login) { "admin" }
  let(:the_host) { 
    create_host(host_login).tap do |role|
      resource = role.resource
      # puts "annotations", resource.annotations
      resource.add_annotation(name: "authn-k8s/namespace", value: "default")
      resource.add_annotation(name: "authn-k8s/authentication-container-name", value: "bash")
      resource.reload
      role.reload
    end
  }
  let(:account) { "rspec" }
  let(:authenticator) { "authn-k8s/meow" }
  let(:authenticate_url) do
    "/#{authenticator}/#{account}/host%2F#{host_login}/authenticate"
  end
  describe "#authenticate" do
    # include_context "create host"
    
    def invoke()
     

      service_id = "conjur/authn-k8s/meow"
      service_id = "conjur/authn-k8s/meow"
      webservice_resource_id = "#{account}:webservice:#{service_id}"

      # puts "Authentication::InstalledAuthenticators.enabled_authenticators_str", Authentication::InstalledAuthenticators.enabled_authenticators_str
      # puts "Rails.application.config.conjur_config.authenticators", Rails.application.config.conjur_config.authenticators
      # allow(ENV).to receive(:[]).and_call_original
      
      allow(Authentication::InstalledAuthenticators).to receive(:enabled_authenticators_str).and_return('authn,authn-k8s/meow')
      allow_any_instance_of(Authentication::Webservices).to receive(:include?).and_return(true)
# enabled_authenticators_str
      

      # ca_for_webservice = gen_authn(account, service_id, host, "http://localhost:9999", "---", "sha256~alfRU3ZmgFlmQFkpzwA9YFACZtMpMsPz2OpCtnJh_fU")

      # Create authenticator instance by applying policy
      authenticator_policy = %Q(
---
# In the spirit of
# https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Integrations/k8s-ocp/k8s-app-identity.htm?tocpath=Integrations%7COpenShift%252FKubernetes%7CSet%20up%20applications%7C_____4

# Define test app host
- !host
  id: #{host_login}
  annotations:
    authn-k8s/namespace: default
    authn-k8s/authentication-container-name: bash
    authn-k8s/namespace-label-selector: a=b,c=d
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
    role: !host /#{host_login}
    privilege: [ read, authenticate ]
    resource: !webservice
)
      post(policies_url, env: request_env.merge({ 'RAW_POST_DATA' => authenticator_policy }))
      expect(response.code).to eq("201")

      # Populate authenticator webservice CA values
      ::Repos::ConjurCA.create(webservice_resource_id)
      
      # Popuplate authenticator configuration variables
      set_secret("#{account}:variable:#{service_id}/kubernetes/api-url", "http://localhost:1234")
      set_secret("#{account}:variable:#{service_id}/kubernetes/ca-cert", "---")
      set_secret("#{account}:variable:#{service_id}/kubernetes/service-account-token", "sha256~X7FlQf3cQZ7e82rDOHmZGmfyQwMN9JMUyx7RNcfzfUE")

      # Permit host to authenticate with webservice
      # webservice_resource.permit("authenticate", the_host)

      hostpkey = OpenSSL::PKey::RSA.new(2048)      
      alt_names = [
        "URI:spiffe://cluster.local/namespace/default/pod/bash-8449b79d7-c2fwd"
      ]
      smart_csr = Util::OpenSsl::X509::SmartCsr.new(
        Util::OpenSsl::X509::QuickCsr.new(common_name: "host.#{host_login}", rsa_key: hostpkey, alt_names: alt_names).request
      )
      # smart_csr = ::Util::OpenSsl::X509::SmartCsr.new(csr)
      signed = Repos::ConjurCA.ca(webservice_resource_id).signed_cert(
        smart_csr,
        subject_altnames: alt_names
      )
      
      # puts "signed", signed
      # cert_resource = ::Conjur::CaInfo.new(id)
      # puts Resource[cert_resource.cert_id].identifier
      # allow(Rails.application.config.conjur_config.authenticators).and_return(['authn-k8s/meow'])

      payload = { 
        'HTTP_X_SSL_CLIENT_CERTIFICATE' => CGI.escape(signed.to_s),
        # 'RAW_POST_DATA' => the_host.credentials.api_key 
      }
      post(authenticate_url, env: payload)
    end
    
    context "with api key" do
      it "is unauthorized" do
        # expect(response.code).to eq("201")
        # expect(response.body).to eq("meow")
        server_thread = AuthnK8sTestServer.run_async
        sleep(1)

        invoke
        expect(response.status).to eq(200)
        # expect(response.body).to eq("meow")
        expect(response).to be_ok
        token = Slosilo::JWT.parse_json(response.body)
        expect(token.claims['sub']).to eq("host/#{host_login}")
        expect(token.signature).to be
        expect(token.claims).to have_key('iat')
      end
    end
  end

  before(:all) do
    # # there doesn't seem to be a sane way to get this
    # @original_database_cleaner_strategy =
    #   DatabaseCleaner.connections.first.strategy
    #     .class.name.downcase[/[^:]+$/].intern

    # # we need truncation here because the tests span many transactions
    # DatabaseCleaner.strategy = :truncation

    # init Slosilo key
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.create(role_id: 'rspec:user:admin')
  end

  after(:all) do
    # before/after(:all) is not transactional; see https://www.relishapp.com/rspec/rspec-rails/docs/transactions
    DatabaseCleaner.clean_with(:truncation)
  end
end

#  echo |  openssl s_client -showcerts -connect api.openshift-48.dev.conjur.net:6443 2>/dev/null | openssl x509 -text
# bundle exec rspec --format documentation ./spec/controllers/authenticate_controller_authn_k8s_spec.rb