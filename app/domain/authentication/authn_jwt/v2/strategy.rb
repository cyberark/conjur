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

          # binding.pry

          if @authenticator.jwks_uri.present?
            additional_params = {
              algorithms: %w[RS256 RS384 RS512],
              verify_iat: true
            }.tap do |hash|
              # binding.pry
              if @authenticator.issuer.present?
                hash[:iss] = @authenticator.issuer
                hash[:verify_iss] = true
              end
              if @authenticator.audience.present?
                hash[:aud] = @authenticator.audience
                hash[:verify_aud] = true
              end
              hash[:jwks] = jwk_loader
            end

            # Request body comes in in the form 'jwt=<token>'
            jwt_token = request_body.split('=').last

            # binding.pry
            begin
              token = @jwt.decode(
                jwt_token,
                nil,
                true, # Verify the signature of this token
                **additional_params
              ).first
            rescue JWT::ExpiredSignature
              raise Errors::Authentication::Jwt::TokenExpired
            rescue JWT::DecodeError => e
              # binding.pry
              raise Errors::Authentication::Jwt::TokenDecodeFailed, e.inspect
            rescue => e
              raise Errors::Authentication::Jwt::TokenVerificationFailed, e.inspect
            end
            if @authenticator.audience.present?
              manditory_claims = %w[exp aud]
            else
              # Lots of tests pass because we don't set audience :( ...
              manditory_claims = %w[exp]
            end
            (manditory_claims - token.keys).each do |missing_claim|
              raise Errors::Authentication::AuthnJwt::MissingMandatoryClaim, missing_claim
            end
            token
            # binding.pry
          else
            raise 'JWT validation from a local file is not yet supported....'
          end
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
            # response = @http.get_response(uri)
            response = http.request(@http::Get.new(uri.path))
          rescue Exception => e
            # binding.pry
            raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
              @authenticator.jwks_uri,
              e.inspect
            )
          end
          return unless response.code.to_i == 200
          # binding.pry
          @json.parse(response.body)
        end

        def jwks(force: false)
          # @cache.fetch(@cache_key, force: force, skip_nil: true) do
          #   fetch_jwks
          # end&.deep_symbolize_keys
          fetch_jwks&.deep_symbolize_keys
        end
      end
    end
  end
end
