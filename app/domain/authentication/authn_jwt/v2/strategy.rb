# frozen_string_literal: true

require 'jwt'
require 'openid_connect'

module Authentication
  module AuthnJwt
    module V2
      # Handles validation of the request body for JWT
      class Strategy
        def initialize(
          authenticator:,
          logger: Rails.logger,
          cache: Rails.cache,
          oidc_discovery_configuration: ::OpenIDConnect::Discovery::Provider::Config
        )
          @authenticator = authenticator
          @logger = logger
          @cache_key = "authenticators/authn-jwt/#{authenticator.account}-#{authenticator.service_id}/jwks-json"
          @cache = cache
          @oidc_discovery_configuration = oidc_discovery_configuration

          # These could be candidates for dependency injection, but currently
          # are not required.
          @jwt = JWT
          @json = JSON
          @http = Net::HTTP
        end

        def validate_request(parameters)
          return if (@authenticator.token_app_property.present? && parameters[:id].blank?) ||
            (@authenticator.token_app_property.blank? && parameters[:id].present?)

          raise(Errors::Authentication::AuthnJwt::IdentityMisconfigured)
        end

        # This method is the primary access point for authentication.
        #
        # @param [String] request_body - POST body content
        # @param [Hash] parameters - GET parameters on the request
        #
        # @return [Authenticator::RoleIdentifier] - Information required to match a Conjur Role
        #
        # The parameter arguement is required by the AuthenticationHandler,
        # but not used by this strategy.
        #
        # rubocop:disable Lint/UnusedMethodArgument
        #
        def callback(request_body:, parameters: nil)
          # Notes - in accordance with best practices, we REALLY should be verify that
          # the following claims are present:
          # - issuer
          # - audience

          validate_request(parameters)

          # Extract JWT Token
          token = verify_jwt_authenticity(
            parse_body(request_body)
          )

          required_jwt_claims_present?(token)

          annotations = gather_enforced_claims(flatten_hash(token))
          role_identifier = extract_role_and_type(id: parameters[:id], jwt: token)

          Authentication::Base::RoleIdentifier.new(
            role_identifier: role_identifier,
            annotations: annotations
            # **{
            #   account: @authenticator.account,
            #   annotations: annotations
            # }.merge(extract_role_and_type(id: parameters[:id], jwt: token))
          )
        end
        # rubocop:enable Lint/UnusedMethodArgument

        # Called by status handler. This handles checking as much of the strategy
        # integrity as possible without performing an actual authentication.
        def verify_status
          jwks_source.call({})
        end

        private

        def extract_role_and_type(id:, jwt:)
          if id
            if id.match(%r{^host/})
              role_identifier = id.gsub(%r{^host/}, '')
              "#{@account}:host:#{role_identifier}"
              # { role_id: role_identifier, type: 'host' }
            else
              "#{@account}:user:#{role_identifier}"
              # { role_id: id, type: 'user' }
            end
          else
            # If we're resolving from the JWT, assume it's a host
            role_identifier = retrieve_identity_from_jwt(jwt: jwt)
            # { role_id: retrieve_identity_from_jwt(jwt: jwt), type: 'host' }
            "#{@account}:host:#{role_identifier}"
          end
        end

        def validate_identity(identity)
          unless identity.present?
            raise(Errors::Authentication::AuthnJwt::NoSuchFieldInToken, @authenticator.token_app_property)
          end

          return identity if identity.is_a?(String)

          raise Errors::Authentication::AuthnJwt::TokenAppPropertyValueIsNotString.new(
            @authenticator.token_app_property,
            identity.class
          )
        end

        def retrieve_identity_from_jwt(jwt:)
          # Handle nested claim lookups
          identity = validate_identity(
            jwt.dig(*@authenticator.token_app_property.split('/')) || jwt[@authenticator.token_app_property]
          )

          # If identity path is present, prefix it to the identity
          # Make sure we allow flexibility for optionally included trailing slash on identity_path
          (@authenticator.identity_path.to_s.split('/').compact << identity).join('/')
        end

        # def identifier(id:, jwt:)
        #   # User ID should only be present without `token-app-property` because
        #   # we'll use the id to lookup the host/user

        #   # NOTE: `token_app_property` maps the specified jwt claim to a host of the
        #   # same name.
        #   if @authenticator.token_app_property.present? && !id.present?
        #     retrieve_identity_from_jwt(jwt: jwt) # , token_app_property: @authenticator.token_app_property, identity_path: @authenticator.identity_path)
        #   elsif id.present? && !@authenticator.token_app_property.present?
        #     id
        #   else
        #     raise Errors::Authentication::AuthnJwt::IdentityMisconfigured
        #   end
        # end

        def parse_body(request_body)
          # Request body comes in in the form 'jwt=<token>'
          body = {}.tap do |hsh|
            parts = request_body.split('=')
            hsh[parts[0]] = parts[1]
          end

          return body['jwt'] if body.key?('jwt') && body['jwt'].present?

          raise(Errors::Authentication::RequestBody::MissingRequestParam, 'jwt')
        end

        def verify_jwt_authenticity(jwt)
          @jwt.decode(
            jwt,
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
        # Allow Provider Discovery exception to bubble up
        rescue Errors::Authentication::OAuth::ProviderDiscoveryFailed => e
          raise e
        rescue => e
          # Handle any unexpected exceptions in the decode section.
          # NOTE: All errors resulting from a failure to decode are part of the
          #   `JWT::DecodeError` family.
          raise Errors::Authentication::Jwt::TokenVerificationFailed, e.inspect
        end

        def additional_params
          {
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
        end

        # {
        #   'foo' => {
        #     'bar' => {
        #       'baz' => 'bang'
        #     }
        #   },
        #   'bing' => 'baz',
        #   'bop' => {
        #     'bing' => ['foo', 'bar']
        #   }
        # }
        # results in:
        # {
        #   'foo/bar/baz' => 'bang',
        #   'bing' => 'baz',
        #   'bop/bing' => ['foo', 'bar']
        # }
        def flatten_hash(hash, results = {}, parent_key = '')
          return results unless hash.is_a?(Hash)

          hash.each_key do |key|
            current_key = parent_key.empty? ? key : [parent_key, key].join('/')
            if hash[key].is_a?(Hash)
              results = flatten_hash(hash[key], results, current_key)
            else
              results[current_key] = hash[key]
            end
          end

          results
        end

        # Given a token like:
        # {
        #   "google":{
        #     "claim":"valid_claim"
        #   },
        #   "host":"myapp",
        #   "foo":"bar"
        # }
        #
        # And:
        #   token-app-property: host
        #   enforced-claims: google/claim
        #   claim-aliases: claim:google/claim
        #
        # This method
        #   - returns the claims transformed via alias
        #   - raises exception if enforced claims are missing
        #
        # {
        #   "claim": "valid_claim",
        #   "host": "myapp",
        #   "foo": "bar"
        # }
        def gather_enforced_claims(token)
          # Verify enforced claims are present on JWT token
          missing_claims = @authenticator.enforced_claims - token.keys
          raise(Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing, missing_claims.first) unless missing_claims.count.zero?

          # Replace aliased claims with their alias. This allows for simple
          # annotation comparisons downstream
          token.dup.tap do |rtn_token|
            @authenticator.claim_aliases_lookup.invert.each do |key, key_alias|
              next unless rtn_token.key?(key)

              rtn_token[key_alias] = rtn_token[key]
              rtn_token.delete(key)
            end
          end
        end

        def required_jwt_claims_present?(token)
          # The check for audience "should" go away if we force audience to be
          # required
          manditory_claims = if @authenticator.audience.present?
            %w[exp aud]
          else
            # Lots of tests pass because we don't set audience :( ...
            %w[exp]
          end
          return unless (missing_claim = (manditory_claims - token.keys).first)

          raise Errors::Authentication::AuthnJwt::MissingMandatoryClaim, missing_claim
        end

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
            rescue => e
              raise Errors::Authentication::OAuth::ProviderDiscoveryFailed.new(@authenticator.provider_uri, e.inspect)
            end
          end
        end

        def jwk_loader(jwks_url)
          ->(options) { jwks(jwks_url: jwks_url, force: options[:invalidate]) || {} }
        end

        def temp_ca_certificate(certificate_content, &block)
          ca_certificate = Tempfile.new('ca_certificates')
          begin
            ca_certificate.write(certificate_content)
            ca_certificate.close
            block.call(ca_certificate)
          ensure
            ca_certificate.unlink # deletes the temp file
          end
        end

        def configured_http_client(url)
          uri = URI(url)
          http = @http.new(uri.host, uri.port)
          return http unless uri.instance_of?(URI::HTTPS)

          # Enable SSL support
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER

          store = OpenSSL::X509::Store.new
          # If CA Certificate is available, we write it to a tempfile for
          # import. This allows us to handle certificate chains.
          if @authenticator.ca_cert.present?
            temp_ca_certificate(@authenticator.ca_cert) do |file|
              store.add_file(file.path)
            end
          else
            # Auto-include system CAs unless a CA has been defined
            store.set_default_paths
          end
          http.cert_store = store

          # return the http object
          http
        end

        def jwks_url_path(url)
          # If path is an empty string, the get request will fail. We set it to a slash if it is empty.
          uri = URI(url)
          uri_path = uri.path
          return uri_path unless uri_path.empty?

          '/'
        end

        def fetch_jwks(url)
          begin
            response = configured_http_client(url).request(@http::Get.new(jwks_url_path(url)))
          rescue => e
            raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
              url,
              e.inspect
            )
          end

          return @json.parse(response.body) if response.code == '200'

          raise Errors::Authentication::AuthnJwt::FetchJwksKeysFailed.new(
            url,
            "response code: '#{response.code}' - #{response.body}"
          )
        end

        # Caches the JWKS response. This will be expired if the key has
        # changed (and the signing key validation fails).
        def jwks(jwks_url:, force: false)
          # Include a digest of the url to ensure cache is expired if url changes
          @cache.fetch("#{@cache_key}-#{Digest::SHA1.hexdigest(jwks_url)}", force: force, skip_nil: true) do
            fetch_jwks(jwks_url)
          end&.deep_symbolize_keys
        end
      end
    end
  end
end
