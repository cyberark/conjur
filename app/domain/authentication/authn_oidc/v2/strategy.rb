# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class Strategy
        REQUIRED_PARAMS = %i[code nonce].freeze
        ALLOWED_PARAMS = (REQUIRED_PARAMS + %i[code_verifier]).freeze

        def initialize(
          authenticator:,
          client: Authentication::AuthnOidc::V2::Client,
          logger: Rails.logger
        )
          @authenticator = authenticator
          binding.pry
          @client = client.new(authenticator: authenticator)
          @logger = logger

          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        def callback(parameters:, request_body: nil)
          # NOTE: `code_verifier` param is optional
          REQUIRED_PARAMS.each do |param|
            unless parameters[param].present?
              return @failure.new(
                "Missing parameter: '#{param}'",
                exception: Errors::Authentication::RequestBody::MissingRequestParam.new(
                  param.to_s
                )
              )
            end
          end

          identity = resolve_identity(
            jwt: @client.callback_with_temporary_cert(
              code: args[:code],
              nonce: args[:nonce],
              code_verifier: args[:code_verifier],
              cert_string: @authenticator.ca_cert
            )
          )
          if identity.present?
            return @success.new(
              Authentication::Base::RoleIdentifier.new(
                role_identifier: identity
              )
            )
          end

          # unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty.new(
              @authenticator.claim_mapping,
              "claim-mapping"
            )
          # end
          # identity
        end

        # Called by status handler. This handles checking as much of the strategy
        # integrity as possible without performing an actual authentication.
        def verify_status
          @client.discover
        end

        private

        def resolve_identity(jwt:)
          jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
        end
      end

      class Client
        def initialize(
          authenticator:,
          client: ::OpenIDConnect::Client,
          oidc_id_token: ::OpenIDConnect::ResponseObject::IdToken,
          discovery_configuration: ::OpenIDConnect::Discovery::Provider::Config,
          cache: Rails.cache,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @client = client
          @oidc_id_token = oidc_id_token
          @discovery_configuration = discovery_configuration
          @cache = cache
          @logger = logger
        end

        # Writing certificates to the default system cert store requires
        # superuser privilege. Instead, Conjur will use ${CONJUR_ROOT}/tmp/certs.
        def self.default_cert_dir(dir: Dir, fileutils: FileUtils)
          if @default_cert_dir.blank?
            conjur_root = __dir__.slice(0..(__dir__.index('/app')))
            @default_cert_dir = File.join(conjur_root, "tmp/certs")
          end

          fileutils.mkdir_p(@default_cert_dir) unless dir.exist?(@default_cert_dir.to_s)

          @default_cert_dir
        end

        def oidc_client
          @oidc_client ||= begin
            issuer_uri = URI(@authenticator.provider_uri)
            @client.new(
              identifier: @authenticator.client_id,
              secret: @authenticator.client_secret,
              redirect_uri: @authenticator.redirect_uri,
              scheme: issuer_uri.scheme,
              host: issuer_uri.host,
              port: issuer_uri.port,
              authorization_endpoint: URI(discovery_information.authorization_endpoint).path,
              token_endpoint: URI(discovery_information.token_endpoint).path,
              userinfo_endpoint: URI(discovery_information.userinfo_endpoint).path,
              jwks_uri: URI(discovery_information.jwks_uri).path
            )
          end
        end

        def callback(code:, nonce:, code_verifier: nil)
          oidc_client.authorization_code = code
          access_token_args = { client_auth_method: :basic }
          access_token_args[:code_verifier] = code_verifier if code_verifier.present?
          begin
            bearer_token = oidc_client.access_token!(**access_token_args)
          rescue Rack::OAuth2::Client::Error => e
            # Only handle the expected errors related to access token retrieval.
            case e.message
            when /PKCE verification failed/, # Okta's PKCE failure msg
                 /challenge mismatch/        # Identity's PKCE failure msg
              raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
                    'PKCE verification failed'
            when /The authorization code is invalid or has expired/, # Okta's reused code msg
                 /supplied code does not match known request/        # Identity's reused code msg
              raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
                    'Authorization code is invalid or has expired'
            when /Code not valid/
              raise Errors::Authentication::AuthnOidc::TokenRetrievalFailed,
                    'Authorization code is invalid'
            end
            raise e
          end
          id_token = bearer_token.id_token || bearer_token.access_token

          begin
            attempts ||= 0
            decoded_id_token = @oidc_id_token.decode(
              id_token,
              discovery_information.jwks
            )
          rescue StandardError => e
            attempts += 1
            raise e if attempts > 1

            # If the JWKS verification fails, blow away the existing cache and
            # try again. This is intended to handle the case where the OIDC certificate
            # changes, and we want to cache the new certificate without decode failing.
            discovery_information(invalidate: true)
            retry
          end

          begin
            decoded_id_token.verify!(
              issuer: @authenticator.provider_uri,
              client_id: @authenticator.client_id,
              nonce: nonce
            )
          rescue OpenIDConnect::ResponseObject::IdToken::InvalidNonce
            raise Errors::Authentication::AuthnOidc::TokenVerificationFailed,
                  'Provided nonce does not match the nonce in the JWT'
          rescue OpenIDConnect::ResponseObject::IdToken::ExpiredToken
            raise Errors::Authentication::AuthnOidc::TokenVerificationFailed,
                  'JWT has expired'
          rescue OpenIDConnect::ValidationFailed => e
            raise Errors::Authentication::AuthnOidc::TokenVerificationFailed,
                  e.message
          end
          decoded_id_token
        end

        # callback_with_temporary_cert wraps the callback method with commands
        # to write & clean up a given certificate or cert chain in a given
        # directory. By default, ${CONJUR_ROOT}/tmp/certs is used.
        #
        # The temporary certificate file name is "x.n", where x is the hash of
        # the certificate subject name, and n is incrememnted from 0 in case of
        # collision.
        #
        # Unlike self.discover, which wraps a single ::OpenIDConnect method,
        # callback_with_temporary_cert wraps the entire callback method, which
        # includes multiple calls to the OIDC provider, including at least one
        # discover! call. The temporary certs will apply to all required
        # operations.
        def callback_with_temporary_cert(
          code:,
          nonce:,
          code_verifier: nil,
          cert_dir: Authentication::AuthnOidc::V2::Client.default_cert_dir,
          cert_string: nil
        )
          c = -> { callback(code: code, nonce: nonce, code_verifier: code_verifier) }

          return c.call if cert_string.blank?

          begin
            certs_a = ::Conjur::CertUtils.parse_certs(cert_string)
          rescue OpenSSL::X509::CertificateError => e
            raise Errors::Authentication::AuthnOidc::InvalidCertificate, e.message
          end
          raise Errors::Authentication::AuthnOidc::InvalidCertificate, "provided string does not contain a certificate" if certs_a.empty?

          symlink_a = []

          Dir.mktmpdir do |tmp_dir|
            certs_a.each_with_index do |cert, idx|
              tmp_file = File.join(tmp_dir, "conjur-oidc-client.#{idx}.pem")
              File.write(tmp_file, cert.to_s)

              n = 0
              hash = cert.subject.hash.to_s(16)
              while true
                symlink = File.join(cert_dir, "#{hash}.#{n}")
                break unless File.exist?(symlink)

                n += 1
              end

              File.symlink(tmp_file, symlink)
              symlink_a << symlink
            end

            if OpenIDConnect.http_config.nil? || OpenIDConnect.http_client.ssl.ca_path != cert_dir
              config_proc = proc do |config|
                config.ssl.ca_path = cert_dir
                config.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER
              end

              # OpenIDConnect gem only accepts a single Faraday configuration
              # through calls to its .http_config method, and future calls to
              # the #http_config method return the first config instance.
              #
              # On the first call to OpenIDConnect.http_config, it will pass the
              # new Faraday configuration to its dependency gems that also have
              # nil configs. We can't be certain that each gem is configured
              # with the same Faraday config and need them synchronized, so we
              # inject them manually.
              OpenIDConnect.class_variable_set(:@@http_config, config_proc)
              WebFinger.instance_variable_set(:@http_config, config_proc)
              SWD.class_variable_set(:@@http_config, config_proc)
              Rack::OAuth2.class_variable_set(:@@http_config, config_proc)
            end

            c.call
          ensure
            symlink_a.each{ |s| File.unlink(s) if s.present? && File.symlink?(s) }
          end
        end

        def discovery_information(invalidate: false)
          @cache.fetch(
            "#{@authenticator.account}/#{@authenticator.service_id}/#{URI::Parser.new.escape(@authenticator.provider_uri)}",
            force: invalidate,
            skip_nil: true
          ) do
            self.class.discover(
              provider_uri: @authenticator.provider_uri,
              discovery_configuration: @discovery_configuration,
              cert_string: @authenticator.ca_cert
            )
          rescue Errno::ETIMEDOUT => e
            raise Errors::Authentication::OAuth::ProviderDiscoveryTimeout.new(@authenticator.provider_uri, e.message)
          rescue => e
            raise Errors::Authentication::OAuth::ProviderDiscoveryFailed.new(@authenticator.provider_uri, e.message)
          end
        end

        # discover wraps ::OpenIDConnect::Discovery::Provider::Config.discover!
        # with commands to write & clean up a given certificate or cert chain in
        # a given directory. By default, ${CONJUR_ROOT}/tmp/certs is used.
        #
        # The temporary certificate file name is "x.n", where x is the hash of
        # the certificate subject name, and n is incremented from 0 in case of
        # collision.
        #
        # discover is a class method, because there are a few contexts outside
        # this class where the underlying discover! method is used. Call it by
        # running Authentication::AuthnOIDC::V2::Client.discover(...).
        def self.discover(
          provider_uri:,
          discovery_configuration: ::OpenIDConnect::Discovery::Provider::Config,
          cert_dir: default_cert_dir,
          cert_string: nil,
          jwks: false
        )
          case jwks
          when false
            d = -> { discovery_configuration.discover!(provider_uri) }
          when true
            d = -> { discovery_configuration.discover!(provider_uri).jwks }
          end

          return d.call if cert_string.blank?

          begin
            certs_a = ::Conjur::CertUtils.parse_certs(cert_string)
          rescue OpenSSL::X509::CertificateError => e
            raise Errors::Authentication::AuthnOidc::InvalidCertificate, e.message
          end
          raise Errors::Authentication::AuthnOidc::InvalidCertificate, "provided string does not contain a certificate" if certs_a.empty?

          symlink_a = []

          Dir.mktmpdir do |tmp_dir|
            certs_a.each_with_index do |cert, idx|
              tmp_file = File.join(tmp_dir, "conjur-oidc-client.#{idx}.pem")
              File.write(tmp_file, cert.to_s)

              n = 0
              hash = cert.subject.hash.to_s(16)
              while true
                symlink = File.join(cert_dir, "#{hash}.#{n}")
                break unless File.exist?(symlink)

                n += 1
              end

              File.symlink(tmp_file, symlink)
              symlink_a << symlink
            end

            if OpenIDConnect.http_config.nil? || OpenIDConnect.http_client.ssl.ca_path != cert_dir
              config_proc = proc do |config|
                config.ssl.ca_path = cert_dir
                config.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER
              end

              # OpenIDConnect gem only accepts a single Faraday configuration
              # through calls to its .http_config method, and future calls to
              # the #http_config method return the first config instance.
              #
              # On the first call to OpenIDConnect.http_config, it will pass the
              # new Faraday configuration to its dependency gems that also have
              # nil configs. We can't be certain that each gem is configured
              # with the same Faraday config and need them synchronized, so we
              # inject them manually.
              OpenIDConnect.class_variable_set(:@@http_config, config_proc)
              WebFinger.instance_variable_set(:@http_config, config_proc)
              SWD.class_variable_set(:@@http_config, config_proc)
              Rack::OAuth2.class_variable_set(:@@http_config, config_proc)
            end

            d.call
          ensure
            symlink_a.each{ |s| File.unlink(s) if s.present? && File.symlink?(s) }
          end
        end
      end
    end
  end
end
