require 'uri'
require 'net/http'
require 'base64'

module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for fetching JWK Set from JWKS-uri
      class FetchJwksUriSigningKey

        def initialize(
          jwks_uri:,
          fetch_signing_key:,
          cert_store: nil,
          http_lib: Net::HTTP,
          create_jwks_from_http_response: CreateJwksFromHttpResponse.new,
          logger: Rails.logger
        )
          @logger = logger
          @http_lib = http_lib
          @create_jwks_from_http_response = create_jwks_from_http_response

          @jwks_uri = jwks_uri
          @fetch_signing_key = fetch_signing_key
          @cert_store = cert_store
        end

        def call(force_fetch:)
          @fetch_signing_key.call(
            refresh: force_fetch,
            cache_key: @jwks_uri,
            signing_key_provider: self
          )
        end

        def fetch_signing_key
          fetch_jwks_keys
          create_jwks_from_http_response
        end

        private

        def fetch_jwks_keys
          jwks_keys
        end

        def jwks_keys
          return @jwks_keys if defined?(@jwks_keys)

          uri = URI(@jwks_uri)
          @logger.info(LogMessages::Authentication::AuthnJwt::FetchingJwksFromProvider.new(@jwks_uri))
          @jwks_keys = net_http_start(
            uri.host,
            uri.port,
            uri.scheme == 'https'
          ) { |http| http.get(uri) }
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchJwtUriKeysSuccess.new)
        rescue => e
          raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
            @jwks_uri,
            e.inspect
          )
        end

        def net_http_start(host, port, use_ssl, &block)
          if @cert_store && !use_ssl
            raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
              @jwks_uri,
              "TLS misconfiguration - ca-cert is provided but jwks-uri URI scheme is http"
            )
          end

          if @cert_store
            net_http_start_with_ca_cert(host, port, use_ssl, &block)
          else
            net_http_start_without_ca_cert(host, port, use_ssl, &block)
          end
        end

        def net_http_start_with_ca_cert(host, port, use_ssl, &block)
          @http_lib.start(
            host,
            port,
            use_ssl: use_ssl,
            cert_store: @cert_store,
            &block
          )
        end

        def net_http_start_without_ca_cert(host, port, use_ssl, &block)
          @http_lib.start(
            host,
            port,
            use_ssl: use_ssl,
            &block
          )
        end

        def create_jwks_from_http_response
          @create_jwks_from_http_response.call(http_response: @jwks_keys)
        end
      end
    end
  end
end
