# frozen_string_literal: true

require 'jwt'
require 'openid_connect'

module Authentication
  module AuthnJwt
    module V2
      class Strategy
        def initialize(
          authenticator:,
          logger: Rails.logger,
          jwt: JWT,
          http: Net::HTTP,
          json: JSON,
          cache: Rails.cache,
          oidc_discovery_configuration: ::OpenIDConnect::Discovery::Provider::Config
        )
          @authenticator = authenticator
          @logger = logger
          @cache_key = "authenticators/authn-jwt/#{authenticator.account}-#{authenticator.service_id}/jwks-json"
          @jwt = jwt
          @json = json
          @http = http
          @cache = cache
          @oidc_discovery_configuration = oidc_discovery_configuration
        end

        def callback(request_body:, parameters: nil)
          # Notes - in accordance with best practices, we REALLY should be verify that
          # the following claims are present:
          # - issuer
          # - audience

          additional_params = {
            algorithms: %w[RS256 RS384 RS512],
            verify_iat: true,
            jwks: jwks_source
          }.tap do |hash|
            if @authenticator.issuer.present?
              hash[:iss] = @authenticator.issuer
              hash[:verify_iss] = true
            end
            if @authenticator.audience.present?
              hash[:aud] = @authenticator.audience
              hash[:verify_aud] = true
            end
          end

          # Request body comes in in the form 'jwt=<token>'
          request_hash = {}.tap do |hsh|
            parts = request_body.split('=')
            hsh[parts[0]] = parts[1]
          end
          unless request_hash['jwt'].present?
            raise Errors::Authentication::RequestBody::MissingRequestParam, 'jwt'
          end

          begin
            token = @jwt.decode(
              request_hash['jwt'],
              nil,
              true, # Verify the signature of this token
              **additional_params
            ).first
          rescue JWT::ExpiredSignature
            raise Errors::Authentication::Jwt::TokenExpired
          rescue JWT::DecodeError => e
            # Looks like only the "malformed JWT" decode error has a unique custom exception
            if e.message == 'Not enough or too many segments'
              raise Errors::Authentication::Jwt::RequestBodyMissingJWTToken
            end

            raise Errors::Authentication::Jwt::TokenDecodeFailed, e.inspect
          rescue => e
            # Handle any unexpected exceptions in the decode section.
            # NOTE: All errors resulting from a failure to decode are part of the
            #   `JWT::DecodeError` family.
            raise Errors::Authentication::Jwt::TokenVerificationFailed, e.inspect
          end

          if token.empty?
            raise Errors::Authentication::AuthnJwt::MissingToken
          end

          # The check for audience "should" go away if we force audience to be
          # required
          manditory_claims = if @authenticator.audience.present?
            %w[exp aud iat]
          else
            # Lots of tests pass because we don't set audience :( ...
            %w[exp iat]
          end
          if (missing_claim = (manditory_claims - token.keys).first)
            raise Errors::Authentication::AuthnJwt::MissingMandatoryClaim, missing_claim
          end

          token
        end

        # Called by status handler. This handles checking as much of the strategy
        # integrity as possible without performing an actual authentication.
        def verify_status
          jwks_source.call({})
        end

        private

        def jwks_source
          if @authenticator.jwks_uri.present?
            jwk_loader(@authenticator.jwks_uri)
          elsif @authenticator.public_keys.present?
            # Looks like loading from the public key is really just injesting
            # a JWKS endpoint from a local source.
            keys = @json.parse(@authenticator.public_keys)&.deep_symbolize_keys

            # Presence of the `value` symbol is verified by the Authenticator Contract
            keys[:value]
          elsif @authenticator.provider_uri.present?
            # If we're validating with Provider URI, it means we're operating
            # against an OIDC endpoint.
            begin
              jwk_loader(
                @oidc_discovery_configuration.discover!(
                  @authenticator.provider_uri
                )&.jwks_uri
              )
            rescue StandardError => e
              raise Errors::Authentication::OAuth::ProviderDiscoveryFailed.new(@authenticator.provider_uri, e.inspect)
            end
          end
        end

        def jwk_loader(jwks_url)
          ->(options) do
            jwks(jwks_url: jwks_url, force: options[:invalidate]) || {}
          end
        end

        def fetch_jwks(url)
          uri = URI(url)
          http = @http.new(uri.host, uri.port)
          if uri.instance_of?(URI::HTTPS)
            # Enable SSL support
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER

            store = OpenSSL::X509::Store.new

            # If CA Certificate is available, we write it to a tempfile for import.
            # This allows us to handle certificate chains.
            if @authenticator.ca_cert.present?
              ca_certificates = Tempfile.new('ca_certificates')
              begin
                ca_certificates.write(@authenticator.ca_cert)
                ca_certificates.close
                store.add_file(ca_certificates.path)
              ensure
                ca_certificates.unlink   # deletes the temp file
              end
            else
              # Auto-include system CAs unless a CA has been defined
              store.set_default_paths
            end

            http.cert_store = store
          end

          # If path is an empty string, the get request will fail. We set it to a slash if it is empty.
          path = uri.path.empty? ? '/' : uri.path
          begin
            response = http.request(@http::Get.new(path))
          rescue StandardError => e
            raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
              url,
              e.inspect
            )
          end

          return @json.parse(response.body) if response.code.to_i == 200

          raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
            url,
            "response code: '#{response.code}' - #{response.body}"
          )
        end

        # Caches the JWKS response. This will be expired if the key has
        # changed (and the signing key validation fails).
        def jwks(jwks_url:, force: false)
          @cache.fetch(@cache_key, force: force, skip_nil: true) do
            fetch_jwks(jwks_url)
          end&.deep_symbolize_keys
        end
      end
    end
  end
end
