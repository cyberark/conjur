# frozen_string_literal: true

require 'openssl'
require 'spec_helper'

RSpec.describe(Authentication::AuthnK8s::K8sObjectLookup) do
  let(:webservice) do 
    Authentication::Webservice.new(
      account: 'MockAccount',
      authenticator_name: 'authn-k8s',
      service_id: 'MockService'
    )
  end

  let(:proxy_uri) { URI.parse("http://uri") }

  let(:cert_raw) do
    """-----BEGIN CERTIFICATE-----
MIIDhzCCAm+gAwIBAgIJAJnsrJ1+j9MhMA0GCSqGSIb3DQEBCwUAMD0xETAPBgNV
BAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDASBgNVBAMTC2N1a2Ut
bWFzdGVyMB4XDTE1MTAwNzE2MzAwM1oXDTI1MTAwNDE2MzAwM1owPTERMA8GA1UE
ChMIY3VjdW1iZXIxEjAQBgNVBAsTCUNvbmp1ciBDQTEUMBIGA1UEAxMLY3VrZS1t
YXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCsuZ06Ld4JDhxZ
FcxKVxu7MTjXVv6W8pI7qFKmgr39aNqmDpKYJ1H9aM+r9zaTAeithpM4wJpVswkJ
d0RSuKdm1LOx11yHLyZ1OvlPHFhsVWdZIQZ6R9srhPYBUCMem4sHR5IAcBBX+HkR
35gaPYUl1uFV/9zCniekt92Kdta+it1WL7XinXTBURlhDawiD/kv1C9x6dICEJVe
IT/jRohmqHAoM/JSOQTthaDli3Qvu5K8XAx8UXvWVmv3eStZFVDbC4ZEueRd9KAe
4IZ5FxdpFYkPBgt2lBYeydYKRShyYrDKye1uJBDkeplNaYW4cS4mOhYuRkdKn7MH
uY/xb1lFAgMBAAGjgYkwgYYwKQYDVR0RBCIwIIILY3VrZS1tYXN0ZXKCCWxvY2Fs
aG9zdIIGY29uanVyMB0GA1UdDgQWBBRHpGF7aQbHdORYgQKDC2hV6NzEKzAfBgNV
HSMEGDAWgBRHpGF7aQbHdORYgQKDC2hV6NzEKzAMBgNVHRMEBTADAQH/MAsGA1Ud
DwQEAwIB5jANBgkqhkiG9w0BAQsFAAOCAQEAGZT9Wek1hYluIVaxu03wSKCKIJ4p
KxTHw+mLDapg1y9t3Fa/5IQQK0Bx0xGU2qWiQKjda3vdFPJWO6l6XJvsUY5Nwtm5
Gcsk8l3L/zWCrjrFTH3TdVad5E+DTwVhThelmEjw68AyM+WuOL61j0MItd9mLW74
Lv2zouj9nQBdnUBHWQ0EL/9d5cfaCVu/bFlDfYt7Yj0IzXCuaWZfJeHodU1hmqVX
BvYRjnTB2LSxfmSnkrCeFPmhE11bWVtsLIdrGIgtEMX0/s9xg58QuNnva1U3pJsW
RjvSxre4Xg2qlI9Laybb4oZ4g6DI8hRbL0VdFAsveg6SXg2RxgJcXeJUFw==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDPjCCAiagAwIBAgIVAKW1gdmOFrXt6xB0iQmYQ4z8Pf+kMA0GCSqGSIb3DQEB
CwUAMD0xETAPBgNVBAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDAS
BgNVBAMTC2N1a2UtbWFzdGVyMB4XDTE1MTAwNzE2MzAwNloXDTI1MTAwNDE2MzAw
NlowFjEUMBIGA1UEAwwLY3VrZS1tYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQC9e8bGIHOLOypKA4lsLcAOcDLAq+ICuVxn9Vg0No0m32Ok/K7G
uEGtlC8RidObntblUwqdX2uP7mqAQm19j78UTl1KT97vMmmFrpVZ7oQvEm1FUq3t
FBmJglthJrSbpdZjLf7a7eL1NnunkfBdI1DK9QL9ndMjNwZNFbXhld4fC5zuSr/L
PxawSzTEsoTaB0Nw0DdRowaZgrPxc0hQsrj9OF20gTIJIYO7ctZzE/JJchmBzgI4
CdfAYg7zNS+0oc0ylV0CWMerQtLICI6BtiQ482bCuGYJ00NlDcdjd3w+A2cj7PrH
wH5UhtORL5Q6i9EfGGUCDbmfpiVD9Bd3ukbXAgMBAAGjXDBaMA4GA1UdDwEB/wQE
AwIFoDAdBgNVHQ4EFgQU2jmj7l5rSw0yVb/vlWAYkK/YBwkwKQYDVR0RBCIwIIIL
Y3VrZS1tYXN0ZXKCCWxvY2FsaG9zdIIGY29uanVyMA0GCSqGSIb3DQEBCwUAA4IB
AQBCepy6If67+sjuVnT9NGBmjnVaLa11kgGNEB1BZQnvCy0IN7gpLpshoZevxYDR
3DnPAetQiZ70CSmCwjL4x6AVxQy59rRj0Awl9E1dgFTYI3JxxgLsI9ePdIRVEPnH
dhXqPY5ZIZhvdHlLStjsXX7laaclEtMeWfSzxe4AmP/Sm/er4ks0gvLQU6/XJNIu
RnRH59ZB1mZMsIv9Ii790nnioYFR54JmQu1JsIib77ZdSXIJmxAtraJSTLcZbU1E
+SM3XCE423Xols7onyluMYDy3MCUTFwoVMRBcRWCAk5gcv6XvZDfLi6Zwdne6x3Y
bGenr4vsPuSFsycM03/EcQDT
-----END CERTIFICATE-----\n\n
"""
  end

  let(:cert_raw_stripped) do
    """-----BEGIN CERTIFICATE-----
MIIDhzCCAm+gAwIBAgIJAJnsrJ1+j9MhMA0GCSqGSIb3DQEBCwUAMD0xETAPBgNV
BAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDASBgNVBAMTC2N1a2Ut
bWFzdGVyMB4XDTE1MTAwNzE2MzAwM1oXDTI1MTAwNDE2MzAwM1owPTERMA8GA1UE
ChMIY3VjdW1iZXIxEjAQBgNVBAsTCUNvbmp1ciBDQTEUMBIGA1UEAxMLY3VrZS1t
YXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCsuZ06Ld4JDhxZ
FcxKVxu7MTjXVv6W8pI7qFKmgr39aNqmDpKYJ1H9aM+r9zaTAeithpM4wJpVswkJ
d0RSuKdm1LOx11yHLyZ1OvlPHFhsVWdZIQZ6R9srhPYBUCMem4sHR5IAcBBX+HkR
35gaPYUl1uFV/9zCniekt92Kdta+it1WL7XinXTBURlhDawiD/kv1C9x6dICEJVe
IT/jRohmqHAoM/JSOQTthaDli3Qvu5K8XAx8UXvWVmv3eStZFVDbC4ZEueRd9KAe
4IZ5FxdpFYkPBgt2lBYeydYKRShyYrDKye1uJBDkeplNaYW4cS4mOhYuRkdKn7MH
uY/xb1lFAgMBAAGjgYkwgYYwKQYDVR0RBCIwIIILY3VrZS1tYXN0ZXKCCWxvY2Fs
aG9zdIIGY29uanVyMB0GA1UdDgQWBBRHpGF7aQbHdORYgQKDC2hV6NzEKzAfBgNV
HSMEGDAWgBRHpGF7aQbHdORYgQKDC2hV6NzEKzAMBgNVHRMEBTADAQH/MAsGA1Ud
DwQEAwIB5jANBgkqhkiG9w0BAQsFAAOCAQEAGZT9Wek1hYluIVaxu03wSKCKIJ4p
KxTHw+mLDapg1y9t3Fa/5IQQK0Bx0xGU2qWiQKjda3vdFPJWO6l6XJvsUY5Nwtm5
Gcsk8l3L/zWCrjrFTH3TdVad5E+DTwVhThelmEjw68AyM+WuOL61j0MItd9mLW74
Lv2zouj9nQBdnUBHWQ0EL/9d5cfaCVu/bFlDfYt7Yj0IzXCuaWZfJeHodU1hmqVX
BvYRjnTB2LSxfmSnkrCeFPmhE11bWVtsLIdrGIgtEMX0/s9xg58QuNnva1U3pJsW
RjvSxre4Xg2qlI9Laybb4oZ4g6DI8hRbL0VdFAsveg6SXg2RxgJcXeJUFw==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDPjCCAiagAwIBAgIVAKW1gdmOFrXt6xB0iQmYQ4z8Pf+kMA0GCSqGSIb3DQEB
CwUAMD0xETAPBgNVBAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDAS
BgNVBAMTC2N1a2UtbWFzdGVyMB4XDTE1MTAwNzE2MzAwNloXDTI1MTAwNDE2MzAw
NlowFjEUMBIGA1UEAwwLY3VrZS1tYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQC9e8bGIHOLOypKA4lsLcAOcDLAq+ICuVxn9Vg0No0m32Ok/K7G
uEGtlC8RidObntblUwqdX2uP7mqAQm19j78UTl1KT97vMmmFrpVZ7oQvEm1FUq3t
FBmJglthJrSbpdZjLf7a7eL1NnunkfBdI1DK9QL9ndMjNwZNFbXhld4fC5zuSr/L
PxawSzTEsoTaB0Nw0DdRowaZgrPxc0hQsrj9OF20gTIJIYO7ctZzE/JJchmBzgI4
CdfAYg7zNS+0oc0ylV0CWMerQtLICI6BtiQ482bCuGYJ00NlDcdjd3w+A2cj7PrH
wH5UhtORL5Q6i9EfGGUCDbmfpiVD9Bd3ukbXAgMBAAGjXDBaMA4GA1UdDwEB/wQE
AwIFoDAdBgNVHQ4EFgQU2jmj7l5rSw0yVb/vlWAYkK/YBwkwKQYDVR0RBCIwIIIL
Y3VrZS1tYXN0ZXKCCWxvY2FsaG9zdIIGY29uanVyMA0GCSqGSIb3DQEBCwUAA4IB
AQBCepy6If67+sjuVnT9NGBmjnVaLa11kgGNEB1BZQnvCy0IN7gpLpshoZevxYDR
3DnPAetQiZ70CSmCwjL4x6AVxQy59rRj0Awl9E1dgFTYI3JxxgLsI9ePdIRVEPnH
dhXqPY5ZIZhvdHlLStjsXX7laaclEtMeWfSzxe4AmP/Sm/er4ks0gvLQU6/XJNIu
RnRH59ZB1mZMsIv9Ii790nnioYFR54JmQu1JsIib77ZdSXIJmxAtraJSTLcZbU1E
+SM3XCE423Xols7onyluMYDy3MCUTFwoVMRBcRWCAk5gcv6XvZDfLi6Zwdne6x3Y
bGenr4vsPuSFsycM03/EcQDT
-----END CERTIFICATE-----"""
  end

  context "inside of kubernetes" do
    include_context "running in kubernetes"

    before do
      allow(URI).to receive_message_chain(:parse, :find_proxy)
        .and_return(proxy_uri)
    end

    context "instantiation" do
      it "does not require a webservice" do
        expect { Authentication::AuthnK8s::K8sObjectLookup.new }.not_to raise_error
      end
    end

    subject { Authentication::AuthnK8s::K8sObjectLookup.new(webservice) }

    it "gets the correct api url" do
      expect(subject.api_url).to eq("https://#{kubernetes_api_url}:#{kubernetes_api_port}")
    end

    it "has the correct ssl options" do
      expect(subject.options[:ssl_options]).to include(:cert_store, verify_ssl: OpenSSL::SSL::VERIFY_PEER)
    end

    it "has the correct auth options" do
      expect(subject.options[:auth_options]).to include(bearer_token: kubernetes_service_token)
    end

    it "has the correct proxy uri" do
      expect(subject.options[:http_proxy_uri]).to equal(proxy_uri)
    end
  end

  context "outside of kubernetes" do
    include_context "running outside kubernetes"

    context "instantiation" do
      it "requires a webservice" do
        allow(Authentication::AuthnK8s::K8sContextValue).to receive(:get)
          .with(nil,
                Authentication::AuthnK8s::SERVICEACCOUNT_CA_PATH,
                Authentication::AuthnK8s::VARIABLE_CA_CERT)
          .and_return(nil)

        expect { Authentication::AuthnK8s::K8sObjectLookup.new }.to raise_error(Errors::Authentication::AuthnK8s::MissingCertificate)
      end
    end

    subject { Authentication::AuthnK8s::K8sObjectLookup.new(webservice) }

    it "gets the correct api url" do
      expect(subject.api_url).to eq(kubernetes_api_url)
    end

    it "has the correct ssl options" do
      expect(subject.options[:ssl_options]).to include(:cert_store, verify_ssl: OpenSSL::SSL::VERIFY_PEER)
    end

    it "has the correct auth options" do
      expect(subject.options[:auth_options]).to include(bearer_token: kubernetes_service_token)
    end

    context "when context value contains whitespaces" do
      it "returns the ca_cert value without whitespace" do
        allow(Authentication::AuthnK8s::K8sContextValue).to receive(:get)
          .with(webservice,
            Authentication::AuthnK8s::SERVICEACCOUNT_CA_PATH,
            Authentication::AuthnK8s::VARIABLE_CA_CERT)
          .and_return(cert_raw)

        expect(subject.ca_cert).to eq(cert_raw_stripped)
      end

      it "returns the bearer_token value without whitespace" do
        allow(Authentication::AuthnK8s::K8sContextValue).to receive(:get)
          .with(webservice,
            Authentication::AuthnK8s::SERVICEACCOUNT_TOKEN_PATH,
            Authentication::AuthnK8s::VARIABLE_BEARER_TOKEN)
          .and_return("MockToken\n")

        expect(subject.bearer_token).to eq("MockToken")
      end
    end
  end
end
