# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::SigningKey::SigningKeySettingsBuilder') do

  jwks_uri = "https://host.name/jwks/path"
  provider_uri = "https://host.name"
  public_keys = "{\"json\":\"string\"}"

  invalid_cases = {
    "When no signing key properties is set and hash is empty":
      [ {  },
       "One of the following must be defined: jwks-uri, public-keys, or provider-uri" ],
    "When no signing key properties is set and there are fields in hash":
      [ { "field-1" => "value-1", "field-2" => "value-2", "ca-cert" => "some value"  },
        "One of the following must be defined: jwks-uri, public-keys, or provider-uri" ],
    "When all signing key properties are define":
      [ { "jwks-uri" => jwks_uri, "provider-uri" => provider_uri, "public-keys" => public_keys },
        "jwks-uri, public-keys, and provider-uri cannot be defined simultaneously" ],
    "When jwks-uri and provider-uri signing key properties are define":
      [ { "jwks-uri" => jwks_uri, "provider-uri" => provider_uri },
        "jwks-uri and provider-uri cannot be defined simultaneously" ],
    "When jwks-uri and public-keys signing key properties are define":
      [ { "jwks-uri" => jwks_uri, "public-keys" => public_keys },
        "jwks-uri and public-keys cannot be defined simultaneously" ],
    "When public-keys and provider-uri signing key properties are define":
      [ { "provider-uri" => provider_uri, "public-keys" => public_keys },
        "public-keys and provider-uri cannot be defined simultaneously" ],
    "When ca-cert is defined with provider-uri":
      [ { "provider-uri" => provider_uri, "ca-cert" => "some value" },
        "ca-cert can only be defined together with jwks-uri" ],
    "When ca-cert is defined with public-keys":
      [ { "public-keys" => public_keys, "ca-cert" => "some value" },
        "ca-cert can only be defined together with jwks-uri" ],
    "When issuer is not set with public-keys":
      [ { "public-keys" => public_keys },
        "issuer is mandatory when public-keys is defined" ]
  }

  valid_cases = {
    "When jwks-uri is set":
      [ { "jwks-uri" => jwks_uri, "issuer" => "issuer" },
        "jwks-uri", jwks_uri, nil ],
    "When provider-uri is set":
      [ { "provider-uri" => provider_uri, "issuer" => "issuer" },
        "provider-uri", provider_uri, nil ],
    "When public-uri is set":
      [ { "public-keys" => public_keys, "issuer" => "issuer" },
        "public-keys", nil, public_keys ]

  }

  let(:invalid_ca_cert_hash) {
    {
      "jwks-uri" => jwks_uri,
      "ca-cert" => "-----BEGIN CERTIFICATE-----\nsome value\n-----END CERTIFICATE-----"
    }
  }

  let(:valid_ca_cert_hash) {
    {
      "jwks-uri" => jwks_uri,
      "ca-cert" => "-----BEGIN CERTIFICATE-----
MIICWDCCAcGgAwIBAgIJAL6pqZoB+3rUMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMjIwMTExMTQ0NDIzWhcNMjMwMTExMTQ0NDIzWjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQC/Pxj1F4klL0niuQck8uzplAEsmRIGhjQP267mnBW3uPCD+wzPtvuZvO3IIaCq
A6wsnqDlcMTafHoFy/Z7ECy2POKGaalOrHNUSO+AK1RlJdFRbVztgH4kuEy4lUiI
239a1cCbk1EswSLqR+EqmK8uwSCIIL6il8mdcFRZqGoBAQIDAQABo1AwTjAdBgNV
HQ4EFgQULakgs5bau09AVzcWubwk1d+P+3IwHwYDVR0jBBgwFoAULakgs5bau09A
VzcWubwk1d+P+3IwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQAnAsAU
88JCcizR7Qbfw0Vov9iM1bH94YZkD/8/k3oAVnBMC5VSBKPEKDPRGn6Grjw1SuV8
9CQ1MZBnVyzvQ12wpu5AQkPhaIlB8VWkuqjRFbt5Pj4UvhnwsA6KvkMgsaiXR5Xu
adw3EjiIk0BWdAToCtSGB7FvdcOntgOsvhHrFQ==
-----END CERTIFICATE-----"
    }
  }

  context "Signing keys settings builder" do
    context "Invalid examples" do
      invalid_cases.each do |description, (hash, expected_error_message) |
        context "#{description}" do
          subject do
            Authentication::AuthnJwt::SigningKey::SigningKeySettingsBuilder.new.call(
              signing_key_parameters: hash
            )
          end

          it "raises an error" do
            expect { subject }
              .to raise_error(
                    Errors::Authentication::AuthnJwt::InvalidSigningKeySettings,
                    "CONJ00122E Invalid signing key settings: #{expected_error_message}")
          end
        end
      end
    end

    context "Valid examples" do
      valid_cases.each do |description, (hash, type, uri, signing_keys) |
        context "#{description}" do
          subject do
            Authentication::AuthnJwt::SigningKey::SigningKeySettingsBuilder.new.call(
              signing_key_parameters: hash
            )
          end

          it "returns a valid SigningKeySettings object" do
            expect(subject).to be_a(Authentication::AuthnJwt::SigningKey::SigningKeySettings)
            expect(subject.type).to eq(type)
            expect(subject.uri).to eq(uri)
            expect(subject.signing_keys).to eq(signing_keys)
          end
        end
      end
    end

    context "ca-cert tests" do
      context "ca-cert has an invalid value" do
        subject do
          Authentication::AuthnJwt::SigningKey::SigningKeySettingsBuilder.new.call(
            signing_key_parameters: invalid_ca_cert_hash
          )
        end

        it "raises an error" do
          expect { subject }
            .to raise_error(OpenSSL::X509::CertificateError)
        end
      end

      context "ca-cert has a valid value" do
        subject do
          Authentication::AuthnJwt::SigningKey::SigningKeySettingsBuilder.new.call(
            signing_key_parameters: valid_ca_cert_hash
          )
        end

        it "not to raises an error" do
          expect { subject }
            .not_to raise_error

          expect(subject.cert_store).to be_a(OpenSSL::X509::Store)
        end
      end
    end
  end
end
