# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::V2::Client) do
  def client(config)
    VCR.use_cassette("authenticators/authn-oidc/v2/#{config[:service_id]}/client_load") do
      client = Authentication::AuthnOidc::V2::Client.new(
        authenticator: Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
          provider_uri: config[:provider_uri],
          redirect_uri: "http://localhost:3000/authn-oidc/#{config[:service_id]}/cucumber/authenticate",
          client_id: config[:client_id],
          client_secret: config[:client_secret],
          claim_mapping: "email",
          account: "bar",
          service_id: "baz"
        )
      )
      # The call `oidc_client` queries the OIDC endpoint. As such,
      # we need to wrap this in a VCR call. Calling this before
      # returning the client to allow this call to be more effectively
      # mocked.
      client.oidc_client
      client
    end
  end

  shared_examples 'happy path' do |config|
    describe '.callback', type: 'unit' do
      context 'when credentials are valid' do
        it 'returns a valid JWT token', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-valid_oidc_credentials" do
          travel_to(Time.parse(config[:auth_time])) do
            token = client(config).callback(
              code: config[:code],
              code_verifier: config[:code_verifier],
              nonce: config[:nonce]
            )
            expect(token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
            expect(token.raw_attributes['nonce']).to eq(config[:nonce])
            expect(token.raw_attributes['preferred_username']).to eq(config[:username])
            expect(token.aud).to eq(config[:client_id])
          end
        end
      end
    end

    describe '.callback_with_temporary_cert', type: 'unit' do
      context 'when credentials are valid', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-valid_oidc_credentials" do
        context 'when no cert is required' do
          it 'returns a valid JWT token' do
            travel_to(Time.parse(config[:auth_time])) do
              token = client(config).callback_with_temporary_cert(
                code: config[:code],
                code_verifier: config[:code_verifier],
                nonce: config[:nonce]
              )
              expect(token).to be_a_kind_of(OpenIDConnect::ResponseObject::IdToken)
              expect(token.raw_attributes['nonce']).to eq(config[:nonce])
              expect(token.raw_attributes['preferred_username']).to eq(config[:username])
              expect(token.aud).to eq(config[:client_id])
            end
          end
        end

        context 'when valid certificate is provided' do
          let(:cert) { <<~EOF
            -----BEGIN CERTIFICATE-----
            MIIDqzCCApOgAwIBAgIJAP9vSJDyPfQdMA0GCSqGSIb3DQEBCwUAMGwxCzAJBgNV
            BAYTAlVTMRYwFAYDVQQIDA1NYXNzYWNodXNldHRzMQ8wDQYDVQQHDAZOZXd0b24x
            ETAPBgNVBAoMCEN5YmVyQXJrMQ8wDQYDVQQLDAZDb25qdXIxEDAOBgNVBAMMB1Jv
            b3QgQ0EwHhcNMjMwODIzMjIyMjU1WhcNMzExMTA5MjIyMjU1WjBsMQswCQYDVQQG
            EwJVUzEWMBQGA1UECAwNTWFzc2FjaHVzZXR0czEPMA0GA1UEBwwGTmV3dG9uMREw
            DwYDVQQKDAhDeWJlckFyazEPMA0GA1UECwwGQ29uanVyMRAwDgYDVQQDDAdSb290
            IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7YPg2tpJYygd37RB
            JQrAEnqtMctB01jSB4Snm3oQVz33z1OfLulTeJA56gwWN4OVm737zUJM1GET6fFC
            ZIVsrhk8WsKeilnyE3FeVMmpbbteUt7DcTS2bpmk6p0MlaN8Y3EoDmVLKmcAoRXS
            xLi8iOkClJPbpSbjQDg2ZnpyfEFBE+jhOWaFkgaSVt2tTUrAt3+F/3o6rRtsXplC
            m2Fj/qK9x4Yw5sw098ztLNNomMCmhSD4ACn4jSZoq0HTH9QrZ9agXTpKkDOeAjMJ
            O08T4XqW61o1YJRPjgIYqwtyCs5DHSzj4AmuYRSDRBgK/mIDDiQd9XL0VFW8CcKP
            DnxSdQIDAQABo1AwTjAdBgNVHQ4EFgQU2/KbZMd7y7ZBfK884/4vB0AAg+AwHwYD
            VR0jBBgwFoAU2/KbZMd7y7ZBfK884/4vB0AAg+AwDAYDVR0TBAUwAwEB/zANBgkq
            hkiG9w0BAQsFAAOCAQEAr2UxJLH5j+3iez0mSwPY2m6QqK57mUWDzgMFHCtuohYT
            saqhBXzsgHqFElw2WM2fQpeSxHqr0R1MrDz+qBg/tgFJ6AnVkW56v41oJb+kZsi/
            fhk7OhU9MhOqG9Wlnptp4QiLCCuKeDUUfQCnu15peR9vxQt0cLlzmr8MQdTuMvb9
            Vi7jey+Y5P04D8sqNP4BNUSRW8TwAKWkPJ4r3GybMsoCwqhb9+zAeYUj30TaxzKK
            VSC0BRw+2QY8OllJPYIE3SCPK+v4SZp72KZ9ooSV+52ezmOCARuNWaNZKCbdPSme
            DBHPd2jZXDVr5nrOEppAnma6VgmlRSN393j6GOiNIw==
            -----END CERTIFICATE-----
          EOF
          }
          let(:cert_subject_hash) { OpenSSL::X509::Certificate.new(cert).subject.hash.to_s(16) }
          let(:symlink_path) { File.join(OpenSSL::X509::DEFAULT_CERT_DIR, "#{cert_subject_hash}.0") }

          it 'cleans up the temporary certificate file' do
            travel_to(Time.parse(config[:auth_time])) do
              expect(File.exist?(symlink_path)).to be false
              client(config).callback_with_temporary_cert(
                code: config[:code],
                code_verifier: config[:code_verifier],
                nonce: config[:nonce],
                cert_string: cert
              )
              expect(File.exist?(symlink_path)).to be false
            end
          end

          context 'if a symlink for the certificate subject already exists' do
            before(:each) do
              @tempfile = Tempfile.new("rspec.pem")
              File.symlink(@tempfile, symlink_path)
            end

            after(:each) do
              @tempfile.close!
              File.unlink(symlink_path)
            end

            it 'maintains the certificate file' do
              travel_to(Time.parse(config[:auth_time])) do
                client(config).callback_with_temporary_cert(
                  code: config[:code],
                  code_verifier: config[:code_verifier],
                  nonce: config[:nonce],
                  cert_string: cert
                )
                expect(File.exist?(symlink_path)).to be true
              end
            end
          end
        end
      end
    end
  end

  shared_examples 'token retrieval failures' do |config|
    describe '.callback', type: 'unit' do
      context 'when code verifier does not match' do
        it 'raises an error', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-invalid_code_verifier" do
          travel_to(Time.parse(config[:auth_time])) do
            expect do
              client(config).callback(
                code: config[:code],
                code_verifier: 'bad-code-verifier',
                nonce: config[:nonce]
              )
            end.to raise_error(
              Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
              "CONJ00133E Access Token retrieval failure: 'PKCE verification failed'"
            )
          end
        end
      end

      context 'when code has previously been used' do
        it 'raise an exception', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-used_code-valid_oidc_credentials" do
          expect do
            client(config).callback(
              code: config[:code],
              code_verifier: config[:code_verifier],
              nonce: config[:nonce]
            )
          end.to raise_error(
            Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
            "CONJ00133E Access Token retrieval failure: 'Authorization code is invalid or has expired'"
          )
        end
      end

      context 'when code has expired', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-expired_code-valid_oidc_credentials" do
        it 'raise an exception' do
          expect do
            client(config).callback(
              code: config[:code],
              code_verifier: config[:code_verifier],
              nonce: config[:nonce]
            )
          end.to raise_error(
            Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
            "CONJ00133E Access Token retrieval failure: 'Authorization code is invalid or has expired'"
          )
        end
      end
    end

    describe '.callback_with_temporary_cert', type: 'unit' do
      context 'when invalid cert is provided', vcr: 'enabled' do
        context 'string does not contain a certificate' do
          let(:cert) { "does not contain a certificate" }

          it 'raises an error' do
            expect do
              client(config).callback_with_temporary_cert(
                code: config[:code],
                code_verifier: config[:code_verifier],
                nonce: config[:nonce],
                cert_string: cert
              )
            end.to raise_error(Errors::Authentication::AuthnOidc::InvalidCertificate)
          end
        end

        context 'string contains malformed certificate' do
          let(:cert) { <<~EOF
            -----BEGIN CERTIFICATE-----
            hello future contributor :)
            -----END CERTIFICATE-----
          EOF
          }

          it 'raises an error' do
            expect do
              client(config).callback_with_temporary_cert(
                code: config[:code],
                code_verifier: config[:code_verifier],
                nonce: config[:nonce],
                cert_string: cert
              )
            end.to raise_error(Errors::Authentication::AuthnOidc::InvalidCertificate)
          end
        end
      end
    end
  end

  shared_examples 'token validation failures' do |config|
    describe '.callback', type: 'unit' do
      context 'when nonce does not match' do
        it 'raises an error', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-valid_oidc_credentials" do
          travel_to(Time.parse(config[:auth_time])) do
            expect do
              client(config).callback(
                code: config[:code],
                code_verifier: config[:code_verifier],
                nonce: 'bad-nonce'
              )
            end.to raise_error(
              Errors::Authentication::AuthnOidc::TokenVerificationFailed,
              "CONJ00128E JWT Token validation failed: 'Provided nonce does not match the nonce in the JWT'"
            )
          end
        end
      end

      context 'when JWT has expired' do
        it 'raises an error', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_callback-valid_oidc_credentials" do
          travel_to(Time.parse(config[:auth_time]) + 86400) do
            expect do
              client(config).callback(
                code: config[:code],
                code_verifier: config[:code_verifier],
                nonce: config[:nonce]
              )
            end.to raise_error(
              Errors::Authentication::AuthnOidc::TokenVerificationFailed,
              "CONJ00128E JWT Token validation failed: 'JWT has expired'"
            )
          end
        end
      end
    end
  end

  shared_examples 'client setup' do |config|
    describe '.oidc_client', type: 'unit' do
      context 'when credentials are valid' do
        it 'returns a valid oidc client', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/client_initialization" do
          oidc_client = client(config).oidc_client

          expect(oidc_client).to be_a_kind_of(OpenIDConnect::Client)
          expect(oidc_client.identifier).to eq(config[:client_id])
          expect(oidc_client.secret).to eq(config[:client_secret])
          expect(oidc_client.redirect_uri).to eq("http://localhost:3000/authn-oidc/#{config[:service_id]}/cucumber/authenticate")
          expect(oidc_client.scheme).to eq('https')
          expect(oidc_client.host).to eq(config[:host])
          expect(oidc_client.port).to eq(443)
          expect(oidc_client.authorization_endpoint).to eq(config[:expected_authz])
          expect(oidc_client.token_endpoint).to eq(config[:expected_token])
          expect(oidc_client.userinfo_endpoint).to eq(config[:expected_userinfo])
        end
      end
    end

    describe '.discovery_information', type: 'unit', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/discovery_endpoint-valid_oidc_credentials" do
      context 'when credentials are valid' do
        it 'endpoint returns valid data' do
          discovery_information = client(config).discovery_information(invalidate: true)

          expect(discovery_information.authorization_endpoint).to eq("https://#{config[:host]}#{config[:expected_authz]}")
          expect(discovery_information.token_endpoint).to eq("https://#{config[:host]}#{config[:expected_token]}")
          expect(discovery_information.userinfo_endpoint).to eq("https://#{config[:host]}#{config[:expected_userinfo]}")
          expect(discovery_information.jwks_uri).to eq("https://#{config[:host]}#{config[:expected_keys]}")
        end
      end

      context 'when provider URI is invalid', vcr: "authenticators/authn-oidc/v2/#{config[:service_id]}/discovery_endpoint-invalid_oidc_provider" do
        it 'returns an timeout error' do
          client = Authentication::AuthnOidc::V2::Client.new(
            authenticator: Authentication::AuthnOidc::V2::DataObjects::Authenticator.new(
              provider_uri: 'https://foo.bar1234321.com',
              redirect_uri: "http://localhost:3000/authn-oidc/#{config[:service_id]}/cucumber/authenticate",
              client_id: config[:client_id],
              client_secret: config[:client_secret],
              claim_mapping: config[:claim_mapping],
              account: 'bar',
              service_id: 'baz'
            )
          )

          expect{client.discovery_information(invalidate: true)}.to raise_error(
            Errors::Authentication::OAuth::ProviderDiscoveryFailed
          )
        end
      end
    end
  end

  describe 'OIDC client targeting Okta' do
    config = {
      provider_uri: 'https://dev-92899796.okta.com/oauth2/default',
      host: 'dev-92899796.okta.com',
      client_id: '0oa3w3xig6rHiu9yT5d7',
      client_secret: 'e349BMTTIpLO-rPuPqLLkLyH_pO-loUzhIVJCrHj',
      service_id: 'okta-2',
      expected_authz: '/oauth2/default/v1/authorize',
      expected_token: '/oauth2/default/v1/token',
      expected_userinfo: '/oauth2/default/v1/userinfo',
      expected_keys: '/oauth2/default/v1/keys',
      auth_time: '2022-09-30 17:02:17 +0000',
      code: '-QGREc_SONbbJIKdbpyYudA13c9PZlgqdxowkf45LOw',
      code_verifier: 'c1de7f1251849accd99d4839d79a637561b1181b909ed7dc1d',
      nonce: '7efcbba36a9b96fdb5285a159665c3d382abd8b6b3288fcc8d',
      username: 'test.user3@mycompany.com'
    }

    include_examples 'client setup', config
    include_examples 'happy path', config
    include_examples 'token retrieval failures', config
    include_examples 'token validation failures', config
  end

  describe 'OIDC client targeting Identity' do
    config = {
      provider_uri: 'https://redacted-host/redacted_app/',
      host: 'redacted-host',
      client_id: 'redacted-id',
      client_secret: 'redacted-secret',
      service_id: 'identity',
      expected_authz: '/OAuth2/Authorize/redacted_app',
      expected_token: '/OAuth2/Token/redacted_app',
      expected_userinfo: '/OAuth2/UserInfo/redacted_app',
      expected_keys: '/OAuth2/Keys/redacted_app',
      auth_time: '2023-4-10 18:00:00 +0000',
      code: 'puPaKJOr_E25STHsM_-rOo3fgJBz2TKVNsi8GzBvwS41',
      code_verifier: '9625bb8881c08de323bb17242d6b3552e50aec0e999e15c66a',
      nonce: 'f1daadf8108eaf6ccf3295fd679acc5218f776d1aaaa3d270a'
    }

    include_examples 'client setup', config
    include_examples 'token retrieval failures', config
  end

  describe '.discover', type: 'unit' do
    let(:target) { Authentication::AuthnOidc::V2::Client }
    let(:provider_uri) { "https://oidcprovider.com" }
    let(:mock_discovery) { double("Mock Discovery Config") }
    let(:mock_response) { double("Mock Discovery Response") }
    let(:mock_jwks_response) { "Mock JWKS Response" }

    before(:each) do
      @cert_dir = Dir.mktmpdir
    end

    after(:each) do
      FileUtils.remove_entry @cert_dir
    end

    context 'when cert is not provided' do
      it 'does not write the certificate' do
        allow(mock_discovery).to receive(:discover!).with(String) do
          expect(Dir.entries(@cert_dir).select do |entry|
            entry unless [".", ".."].include?(entry)
          end).to be_empty
        end

        target.discover(
          provider_uri: provider_uri,
          discovery_configuration: mock_discovery,
          cert_dir: @cert_dir,
          cert_string: ""
        )
      end

      it 'returns the discovery response' do
        allow(mock_discovery).to receive(:discover!).with(String).and_return(
          mock_response
        )

        expect(target.discover(
          provider_uri: provider_uri,
          discovery_configuration: mock_discovery,
          cert_dir: @cert_dir,
          cert_string: ""
        )).to eq(mock_response)
      end

      it 'invokes the jwks uri when requested' do
        allow(mock_discovery).to receive(:discover!).with(String).and_return(
          mock_response
        )
        allow(mock_response).to receive(:jwks).and_return(
          mock_jwks_response
        )

        expect(target.discover(
          provider_uri: provider_uri,
          discovery_configuration: mock_discovery,
          cert_dir: @cert_dir,
          cert_string: "",
          jwks: true
        )).to eq(mock_jwks_response)
      end
    end

    context 'when valid cert is provided' do
      let(:cert) { <<~EOF
        -----BEGIN CERTIFICATE-----
        MIIDqzCCApOgAwIBAgIJAP9vSJDyPfQdMA0GCSqGSIb3DQEBCwUAMGwxCzAJBgNV
        BAYTAlVTMRYwFAYDVQQIDA1NYXNzYWNodXNldHRzMQ8wDQYDVQQHDAZOZXd0b24x
        ETAPBgNVBAoMCEN5YmVyQXJrMQ8wDQYDVQQLDAZDb25qdXIxEDAOBgNVBAMMB1Jv
        b3QgQ0EwHhcNMjMwODIzMjIyMjU1WhcNMzExMTA5MjIyMjU1WjBsMQswCQYDVQQG
        EwJVUzEWMBQGA1UECAwNTWFzc2FjaHVzZXR0czEPMA0GA1UEBwwGTmV3dG9uMREw
        DwYDVQQKDAhDeWJlckFyazEPMA0GA1UECwwGQ29uanVyMRAwDgYDVQQDDAdSb290
        IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7YPg2tpJYygd37RB
        JQrAEnqtMctB01jSB4Snm3oQVz33z1OfLulTeJA56gwWN4OVm737zUJM1GET6fFC
        ZIVsrhk8WsKeilnyE3FeVMmpbbteUt7DcTS2bpmk6p0MlaN8Y3EoDmVLKmcAoRXS
        xLi8iOkClJPbpSbjQDg2ZnpyfEFBE+jhOWaFkgaSVt2tTUrAt3+F/3o6rRtsXplC
        m2Fj/qK9x4Yw5sw098ztLNNomMCmhSD4ACn4jSZoq0HTH9QrZ9agXTpKkDOeAjMJ
        O08T4XqW61o1YJRPjgIYqwtyCs5DHSzj4AmuYRSDRBgK/mIDDiQd9XL0VFW8CcKP
        DnxSdQIDAQABo1AwTjAdBgNVHQ4EFgQU2/KbZMd7y7ZBfK884/4vB0AAg+AwHwYD
        VR0jBBgwFoAU2/KbZMd7y7ZBfK884/4vB0AAg+AwDAYDVR0TBAUwAwEB/zANBgkq
        hkiG9w0BAQsFAAOCAQEAr2UxJLH5j+3iez0mSwPY2m6QqK57mUWDzgMFHCtuohYT
        saqhBXzsgHqFElw2WM2fQpeSxHqr0R1MrDz+qBg/tgFJ6AnVkW56v41oJb+kZsi/
        fhk7OhU9MhOqG9Wlnptp4QiLCCuKeDUUfQCnu15peR9vxQt0cLlzmr8MQdTuMvb9
        Vi7jey+Y5P04D8sqNP4BNUSRW8TwAKWkPJ4r3GybMsoCwqhb9+zAeYUj30TaxzKK
        VSC0BRw+2QY8OllJPYIE3SCPK+v4SZp72KZ9ooSV+52ezmOCARuNWaNZKCbdPSme
        DBHPd2jZXDVr5nrOEppAnma6VgmlRSN393j6GOiNIw==
        -----END CERTIFICATE-----
      EOF
      }
      let(:cert_subject_hash) { OpenSSL::X509::Certificate.new(cert).subject.hash.to_s(16) }
      let(:symlink_path) { File.join(@cert_dir, "#{cert_subject_hash}.0") }

      it 'writes the certificate to the specified directory' do
        allow(mock_discovery).to receive(:discover!).with(String) do
          expect(File.exist?(symlink_path)).to be true
          expect(File.read(symlink_path)).to eq(cert)
        end

        target.discover(
          provider_uri: provider_uri,
          discovery_configuration: mock_discovery,
          cert_dir: @cert_dir,
          cert_string: cert
        )
      end

      it 'cleans up the certificate after fetching discovery information' do
        allow(mock_discovery).to receive(:discover!).with(String)

        target.discover(
          provider_uri: provider_uri,
          discovery_configuration: mock_discovery,
          cert_dir: @cert_dir,
          cert_string: cert
        )

        expect(File.exist?(symlink_path)).to be false
      end

      context 'when target symlink already exists' do
        before(:each) do
          @tempfile = Tempfile.new("rspec.pem")
          File.symlink(@tempfile, symlink_path)
        end

        after(:each) do
          @tempfile.close!
          File.unlink(symlink_path)
        end

        it 'writes the certificate to the specified directory with incremented name' do
          allow(mock_discovery).to receive(:discover!).with(String) do
            expect(File.exist?(symlink_path)).to be true

            incremented = File.join(@cert_dir, "#{cert_subject_hash}.1")
            expect(File.exist?(incremented))
            expect(File.read(incremented)).to eq(cert)
          end

          target.discover(
            provider_uri: provider_uri,
            discovery_configuration: mock_discovery,
            cert_dir: @cert_dir,
            cert_string: cert
          )
        end

        it 'maintains the original while cleaning up the created cert' do
          allow(mock_discovery).to receive(:discover!).with(String)

          target.discover(
            provider_uri: provider_uri,
            discovery_configuration: mock_discovery,
            cert_dir: @cert_dir,
            cert_string: cert
          )

          expect(File.exist?(symlink_path)).to be true
          expect(File.exist?(File.join(@cert_dir, "#{cert_subject_hash}.1"))).to be false
        end
      end
    end

    context 'when valid cert chain is provided' do
      let(:client_cert) { <<~EOF
        -----BEGIN CERTIFICATE-----
        MIIC6zCCAlQCAQEwDQYJKoZIhvcNAQELBQAwdjELMAkGA1UEBhMCVVMxFjAUBgNV
        BAgMDU1hc3NhY2h1c2V0dHMxDzANBgNVBAcMBk5ld3RvbjERMA8GA1UECgwIQ3li
        ZXJBcmsxDzANBgNVBAsMBkNvbmp1cjEaMBgGA1UEAwwRVW5pdCBUZXN0IFJvb3Qg
        Q0EwHhcNMjMwODI1MTgxMzM1WhcNMzMwODIyMTgxMzM1WjCBgTELMAkGA1UEBhMC
        VVMxFjAUBgNVBAgMDU1hc3NhY2h1c2V0dHMxDzANBgNVBAcMBk5ld3RvbjERMA8G
        A1UECgwIQ3liZXJBcmsxDzANBgNVBAsMBkNvbmp1cjElMCMGA1UEAwwcVW5pdCBU
        ZXN0IENsaWVudCBDZXJ0aWZpY2F0ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
        AQoCggEBAMPeuIWmjgF381jSV2/lgS2tZYkD53ukM9nlnIEI3N4QZ46aD0+tcet+
        2gZ5+TdwceZMc8R8krSuA25Kojn2tvKInyrmWWbIGV2JA+iBeRiMSjbbh4keAWYW
        /HKawCRfdxmYheBEFbbKtFcsKxuIqEmFEdwG7TeJx6wr2zIayenC7I8HzAk7LQSW
        pJb6Fv/gpbagNmnoITeIC58s+ibF77OVk5XW0hFkyO/La46R+WhATp8ayYmXpwWT
        yVemxs4P60N5AK8NvmvRPxuQfOSAP154W0WYD5FtKUcPP3CdOQEZhGjWGiScZ7mr
        6aLYuac4gS7b/kOC+Fzqw3NNY7vUs6MCAwEAATANBgkqhkiG9w0BAQsFAAOBgQB5
        O4a3Qs5zPO2cGW4fX92nmB9jj1sxik+3hVV/aTHNUfAYJ0aula+kKqghbVlrlsAm
        6Oqdw3WCoBkUjqUQqqPlLqmmxA/AW+izqLzvaZnBCGyHiFGYUFhMilk9mfE/m63v
        EhjKF017l50ptBaUYiD1W9IXGWZJ9b1nxnr/S+CXCQ==
        -----END CERTIFICATE-----
      EOF
      }
      let(:client_hash) { OpenSSL::X509::Certificate.new(client_cert).subject.hash.to_s(16) }
      let(:ca_cert) { <<~EOF
        -----BEGIN CERTIFICATE-----
        MIICYzCCAcwCCQCtimZfxnGkRTANBgkqhkiG9w0BAQsFADB2MQswCQYDVQQGEwJV
        UzEWMBQGA1UECAwNTWFzc2FjaHVzZXR0czEPMA0GA1UEBwwGTmV3dG9uMREwDwYD
        VQQKDAhDeWJlckFyazEPMA0GA1UECwwGQ29uanVyMRowGAYDVQQDDBFVbml0IFRl
        c3QgUm9vdCBDQTAeFw0yMzA4MjUxODA5MjJaFw0zMzA4MjIxODA5MjJaMHYxCzAJ
        BgNVBAYTAlVTMRYwFAYDVQQIDA1NYXNzYWNodXNldHRzMQ8wDQYDVQQHDAZOZXd0
        b24xETAPBgNVBAoMCEN5YmVyQXJrMQ8wDQYDVQQLDAZDb25qdXIxGjAYBgNVBAMM
        EVVuaXQgVGVzdCBSb290IENBMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQD0
        r78pu6hJZTKXR4qLHNbZ8sM4IWrTBRerBumf5Qjq3LmNhvMCXYee1Z9YmHOh5UrA
        JbONCM3ASt1INbf3pD52JJEEWA8udEvGhONsnrjuXI2DoBg/W/4rye9p6+SagOSF
        O9oLUIczL4XxIgE1CXi89uwCwn0BxjLnaLraMxvbgQIDAQABMA0GCSqGSIb3DQEB
        CwUAA4GBANUZ4iQLe83CIb4DV73a+OUwZ19YJ0DCMvXDMWW0CTwVv4DhxM8ZkTpu
        1FQ/uXrA9FP/kulYAMLqo8RkYiE+u64Jbs/vWebupyV89dh5sFEsp0PafQa415C6
        h1Tg+4C+eSkQIEIGVm8tLVG8JQL4sweo/gQGdzcxfCSfPZHqInzD
        -----END CERTIFICATE-----
      EOF
      }
      let(:ca_hash) { OpenSSL::X509::Certificate.new(ca_cert).subject.hash.to_s(16) }
      let(:cert_strings) { [ client_cert, ca_cert ] }
      let(:hashes) { [ client_hash, ca_hash ] }
      let(:cert_chain) { "#{client_cert}\n#{ca_cert}" }

      it 'writes all certificates to the specified directory' do
        allow(mock_discovery).to receive(:discover!).with(String) do
          hashes.each_with_index do |hash, i|
            cert_path = File.join(@cert_dir, "#{hash}.0")
            expect(File.exist?(cert_path)).to be true
            expect(File.symlink?(cert_path)).to be true
            expect(File.read(cert_path)).to eq(cert_strings[i])
          end
        end

        target.discover(
          provider_uri: provider_uri,
          discovery_configuration: mock_discovery,
          cert_dir: @cert_dir,
          cert_string: cert_chain
        )
      end

      it 'cleans up all certificates after fetching discovery information' do
        allow(mock_discovery).to receive(:discover!).with(String)

        target.discover(
          provider_uri: provider_uri,
          discovery_configuration: mock_discovery,
          cert_dir: @cert_dir,
          cert_string: cert_chain
        )

        hashes.each do |hash|
          cert_path = File.join(@cert_dir, "#{hash}.0")
          expect(File.exist?(cert_path)).to be false
        end
      end
    end

    context 'when invalid cert is provided' do
      context 'string does not contain a certificate' do
        let(:cert) { "does not contain a certificate" }

        it 'raises an error' do
          expect do
            target.discover(
              provider_uri: provider_uri,
              discovery_configuration: mock_discovery,
              cert_dir: @cert_dir,
              cert_string: cert
            )
          end.to raise_error(Errors::Authentication::AuthnOidc::InvalidCertificate) do |e|
            expect(e.message).to include("provided string does not contain a certificate")
          end
        end
      end

      context 'string contains malformed certificate' do
        let(:cert) { <<~EOF
          -----BEGIN CERTIFICATE-----
          hellofuturecontributor:)
          -----END CERTIFICATE-----
        EOF
        }

        it 'raises an error' do
          expect do
            target.discover(
              provider_uri: provider_uri,
              discovery_configuration: mock_discovery,
              cert_dir: @cert_dir,
              cert_string: cert
            )
          end.to raise_error(Errors::Authentication::AuthnOidc::InvalidCertificate) do |e|
            expect(e.message).to include(cert)
            expect(e.message).to include("nested asn1 error")
          end
        end
      end
    end
  end
end
