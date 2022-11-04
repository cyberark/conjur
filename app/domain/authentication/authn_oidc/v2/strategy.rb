
module Authentication
  module AuthnOidc
    module V2
      module Strategies
        module Common
          def initialize(
            authenticator:,
            client: Authentication::AuthnOidc::V2::Client,
            logger: Rails.logger
          )
            @authenticator = authenticator
            @client = client.new(authenticator: authenticator)
            @logger = logger
          end

          def validate_args(args:, required:)
            if args[:code] && args[:refresh_token]
              raise Errors::Authentication::RequestBody::MultipleXorRequestParams.new('code', 'refresh_token')
            end

            required.each do |param|
              unless args[param].present?
                raise Errors::Authentication::RequestBody::MissingRequestParam, param.to_s
              end
            end
          end

          def authenticate_with_oidc(&block)
            jwt, refresh_token = block.call

            identity = resolve_identity(jwt: jwt)
            unless identity.present?
              raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
                    @authenticator.claim_mapping
            end

            return [identity, {}] if refresh_token.nil?
            [identity, { 'X-OIDC-Refresh-Token' => refresh_token }]
          end

          def resolve_identity(jwt:)
            jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
          end
        end

        class AuthzCode
          include Common

          def callback(args)
            validate_args(args: args, required: %i[code nonce code_verifier])
            authenticate_with_oidc do
              @client.get_token_with_code(
                code: args[:code],
                nonce: args[:nonce],
                code_verifier: args[:code_verifier]
              )
            end
          end
        end

        class RefreshToken
          include Common

          def callback(args)
            validate_args(args: args, required: %i[refresh_token nonce])
            authenticate_with_oidc do
              @client.get_token_with_refresh_token(
                refresh_token: args[:refresh_token],
                nonce: args[:nonce]
              )
            end
          end
        end

        class Logout
          include Common

          def callback(args)
            validate_args(args: args, required: %i[refresh_token nonce state redirect_uri])
            @client.end_session(
              refresh_token: args[:refresh_token],
              nonce: args[:nonce],
              state: args[:state],
              redirect_uri: args[:redirect_uri]
            )
          end
        end
      end
    end
  end
end
