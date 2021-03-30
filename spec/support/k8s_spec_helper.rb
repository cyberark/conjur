# frozen_string_literal: true

def self_signed_certificate
  key = OpenSSL::PKey::RSA.new(2048)
  ca = OpenSSL::X509::Certificate.new
  subject = OpenSSL::X509::Name.parse("/DC=mock/CN=rspec")

  ca.public_key = key.public_key
  ca.subject = subject
  ca.issuer = subject
  ca.version = 2
  ca.serial = 1
  ca.not_before = Time.now
  ca.not_after = Time.now + 60 * 60
  ca.sign(key, OpenSSL::Digest.new('SHA256'))

  ca.to_pem
end

shared_context "running in kubernetes" do
  let(:kubernetes_ca_cert) { self_signed_certificate }
  let(:kubernetes_service_token) { "MockServiceToken" }
  let(:kubernetes_api_url) { "api.mock.internal" }
  let(:kubernetes_api_port) { "443" }
  
  before(:each) do
    allow(Authentication::AuthnK8s::K8sContextValue).to receive(:get)
      .with(anything,
            Authentication::AuthnK8s::SERVICEACCOUNT_CA_PATH,
            Authentication::AuthnK8s::VARIABLE_CA_CERT)
      .and_return(kubernetes_ca_cert)
    
    allow(Authentication::AuthnK8s::K8sContextValue).to receive(:get)
      .with(anything,
            Authentication::AuthnK8s::SERVICEACCOUNT_TOKEN_PATH,
            Authentication::AuthnK8s::VARIABLE_BEARER_TOKEN)
      .and_return(kubernetes_service_token)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[])
      .with("KUBERNETES_SERVICE_HOST")
      .and_return(kubernetes_api_url)

    allow(ENV).to receive(:[])
      .with("KUBERNETES_SERVICE_PORT")
      .and_return(kubernetes_api_port)
  end
end

shared_context "running outside kubernetes" do
  let(:kubernetes_ca_cert) { self_signed_certificate }
  let(:kubernetes_service_token) { "MockServiceToken" }
  let(:kubernetes_api_url) { "https://api.mock.internal:1443" }

  let(:secret_api_url) { double("MockSecretApiUrl", value: kubernetes_api_url) }
  let(:resource_api_url) { double("MockApiUrl", secret: secret_api_url) }

  before(:each) do
    allow(Authentication::AuthnK8s::K8sContextValue).to receive(:get)
      .with(an_instance_of(Authentication::Webservice),
            Authentication::AuthnK8s::SERVICEACCOUNT_CA_PATH,
            Authentication::AuthnK8s::VARIABLE_CA_CERT)
      .and_return(kubernetes_ca_cert)
    
    allow(Authentication::AuthnK8s::K8sContextValue).to receive(:get)
      .with(an_instance_of(Authentication::Webservice),
            Authentication::AuthnK8s::SERVICEACCOUNT_TOKEN_PATH,
            Authentication::AuthnK8s::VARIABLE_BEARER_TOKEN)
      .and_return(kubernetes_service_token)

    allow_any_instance_of(Authentication::Webservice).to receive(:variable)
      .with(Authentication::AuthnK8s::VARIABLE_API_URL)
      .and_return(resource_api_url)
  end
end
