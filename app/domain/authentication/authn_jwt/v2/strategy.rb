# frozen_string_literal: true

require 'jwt'

module Authentication
  module AuthnJwt
    module V2
      class Strategy
        def initialize(
          authenticator:,
          logger: Rails.logger,
          jwt: JWT,
          http: Net::HTTP, # check that this is needed
          json: JSON,
          cache: Rails.cache
        )
          @authenticator = authenticator
          @logger = logger
          @cache_key = "authenticators/authn-jwt/#{authenticator.service_id}/jwks-json"
          @jwt = jwt
          @json = json
          @http = http
          @cache = cache
        end

        def callback(parameters:, request_body:)
          # Notes - in accordance with best practices, we REALLY should be verify that
          # the following claims are present:
          # - issuer
          # - audience

          # Validations....
          if @authenticator.jwks_uri.present? && @authenticator.provider_uri.present?
            raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings,
              "jwks-uri and provider-uri cannot be defined simultaneously"
          end

          if @authenticator.jwks_uri.blank? && @authenticator.provider_uri.blank? && @authenticator.public_keys.blank?
            raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings,
              'One of the following must be defined: jwks-uri, public-keys, or provider-uri'
          end

          additional_params = {
            algorithms: %w[RS256 RS384 RS512],
            verify_iat: true
          }.tap do |hash|
            if @authenticator.jwks_uri.present?
              if @authenticator.issuer.present?
                hash[:iss] = @authenticator.issuer
                hash[:verify_iss] = true
              end
              if @authenticator.audience.present?
                hash[:aud] = @authenticator.audience
                hash[:verify_aud] = true
              end
              hash[:jwks] = jwk_loader
            elsif @authenticator.public_keys.present?
              hash[:iss] = @authenticator.issuer
              hash[:verify_iss] = true
              # Looks like loading from the public key is really just injesting
              # a JWKS endpoint from a local source.
              keys = @json.parse(@authenticator.public_keys)&.deep_symbolize_keys
              hash[:jwks] = keys[:value]
            else
              raise Errors::Authentication::AuthnJwt::InvalidSigningKeySettings,
                'Failed to find a JWT decode option. Either `jwks-uri` or `public-keys` variable must be set.'
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
            if token.empty?
              raise Errors::Authentication::AuthnJwt::MissingToken
            end
          rescue JWT::ExpiredSignature
            raise Errors::Authentication::Jwt::TokenExpired
          rescue JWT::DecodeError => e
            # Looks like only the "malformed JWT" decode error has a unique custom exception
            if e.message == 'Not enough or too many segments'
              raise Errors::Authentication::Jwt::RequestBodyMissingJWTToken
            else
              raise Errors::Authentication::Jwt::TokenDecodeFailed, e.inspect
            end
          rescue => e
            raise Errors::Authentication::Jwt::TokenVerificationFailed, e.inspect
          end

          # The check for audience "should" go away if we force audience to be
          # required
          manditory_claims = if @authenticator.audience.present?
            %w[exp aud]
          else
            # Lots of tests pass because we don't set audience :( ...
            %w[exp]
          end
          (manditory_claims - token.keys).each do |missing_claim|
            raise Errors::Authentication::AuthnJwt::MissingMandatoryClaim, missing_claim
          end
          token
        end

        private

        def jwk_loader
          ->(options) do
            jwks(force: options[:invalidate]) || {}
          end
        end

        def fetch_jwks
          uri = URI(@authenticator.jwks_uri)
          http = @http.new(uri.host, uri.port)
          if uri.instance_of?(URI::HTTPS)
            # Enable SSL support
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER

            store = OpenSSL::X509::Store.new
            # Auto-include system CAs
            store.set_default_paths

            if @authenticator.ca_cert.present?
              store.add_cert(OpenSSL::X509::Certificate.new(@authenticator.ca_cert))
            end

            http.cert_store = store
          end

          begin
            response = http.request(@http::Get.new(uri.path))
          rescue Exception => e
            raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
              @authenticator.jwks_uri,
              e.inspect
            )
          end

          return unless response.code.to_i == 200

          @json.parse(response.body)
        end

        def jwks(force: false)
          # TODO: Need a mechanism to allow us to expire cache from Cucumber tests
          # so that we can include tests with different JWKS certificates.
          #
          # @cache.fetch(@cache_key, force: force, skip_nil: true) do
          #   fetch_jwks
          # end&.deep_symbolize_keys
          fetch_jwks&.deep_symbolize_keys
        end
      end
    end
  end
end
