# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class Strategy < Authentication::AuthnJwt::V2::Strategy
        REQUIRED_PARAMS = %i[code nonce].freeze
        ALLOWED_PARAMS = (REQUIRED_PARAMS + %i[code_verifier]).freeze

        def initialize(
          authenticator:,
          oidc_client: OidcClient,
          jwt_client: JWT,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @oidc_client = oidc_client.new(authenticator: authenticator)
          @logger = logger

          @success = ::SuccessResponse
          @failure = ::FailureResponse

          # Initialize JWT Strategy which will be used to validate the JWT
          # after code exchange.
          super(
            authenticator: authenticator,
            jwt_client: jwt_client,
            logger: logger
          )
        end

        # rubocop:disable Lint/UnusedMethodArgument
        def callback(parameters:, request_body: nil)
          validate_parameters(parameters).bind do |params|
            nonce = params[:nonce]
            exchange_code_for_jwt_token(
              code: params[:code],
              nonce: nonce,
              code_verifier: params[:code_verifier]
            ).bind do |bearer_token|
              jwks_uri_response = @oidc_client.oidc_configuration.bind do |config|
                # `jwks_uri` is manditory in accordance with the OpenID Connect specification:
                # https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata
                @success.new(config['jwks_uri'])
              end

              jwks_uri_response.bind do |jwks_uri|
                # This method lives in Authentication::AuthnJwt::V2::Strategy
                # Once we have the JWT from the OIDC provider, this is really just a JWT
                # authentication exercise.
                #
                # NOTE: OIDC Authenticator does not validate the `aud` claim. This feels like
                # something we should correct...
                decode_jwt(
                  jwt: bearer_token,
                  issuer: @authenticator.provider_uri,
                  jwks_uri: jwks_uri
                ).bind do |decoded_token|
                  verify_token(token: decoded_token, nonce: nonce).bind do |verified_token|
                    identify_role(jwt: verified_token).bind do |identity|
                      @success.new(
                        Authentication::RoleIdentifier.new(
                          identifier: "#{@authenticator.account}:user:#{identity}"
                        )
                      )
                    end
                  end
                end
              end
            end
          end
        end
        # rubocop:enable Lint/UnusedMethodArgument

        # TODO: Enable once the status handler has been implemented
        # # Called by status handler. This handles checking as much of the strategy
        # # integrity as possible without performing an actual authentication.
        # def verify_status
        #   # @client.discover
        #   @oidc_client.configuration
        # end

        private

        def validate_parameters(parameters)
          REQUIRED_PARAMS.each do |param|
            unless parameters[param].present?
              return @failure.new(
                "Missing parameter: '#{param}'",
                exception: Errors::Authentication::RequestBody::MissingRequestParam.new(
                  param.to_s
                ),
                status: :bad_request
              )
            end
          end
          @success.new(parameters.select{|item| ALLOWED_PARAMS.include?(item)})
        end

        def exchange_code_for_jwt_token(code:, nonce:, code_verifier:)
          @oidc_client.exchange_code_for_token(
            code: code,
            nonce: nonce,
            code_verifier: code_verifier
          )
        end

        def identify_role(jwt:)
          identity = jwt[@authenticator.claim_mapping]
          return @success.new(identity) if identity.present?

          @failure.new(
            "Claim '#{@authenticator.claim_mapping}' was not found in the JWT token",
            exception: Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty.new(
              @authenticator.claim_mapping,
              'claim-mapping'
            ),
            status: :unauthorized
          )
        end

        def verify_token(token:, nonce:)
          unless token['nonce'] == nonce
            return @failure.new(
              'Provided nonce does not match the JWT nonce',
              exception: Errors::Authentication::AuthnOidc::NonceVerificationFailed.new,
              status: :bad_request
            )
          end

          @success.new(token)
        end
      end
    end
  end
end
