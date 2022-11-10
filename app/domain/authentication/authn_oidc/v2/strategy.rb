
module Authentication
  module AuthnOidc
    module V2
      class Strategy
        def initialize(
          authenticator:,
          client: Authentication::AuthnOidc::V2::Client,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @client = client.new(authenticator: authenticator)
          @logger = logger
        end

        # Don't love this name...
        def callback(args)
          unless args.key?(:code) ^ args.key?(:refresh_token)
            raise Errors::Authentication::RequestBody::BadXorCombination.new('code', 'refresh_token')
          end

          strategy = if args.key?(:code)
            Strategies::CodeAuthentication
          elsif args.key?(:refresh_token)
            Strategies::RefreshAuthentication
          end

          validate_required_params(args: args, required: strategy.const_get(:REQUIRED_PARAMETERS))

          tokens = strategy.new(
            oidc_client: @client
          ).call(args)

          identity = resolve_identity(jwt: tokens[:id_token])

          {
            :identity => identity,
            :headers => {
              'X-OIDC-Refresh-Token' => tokens[:refresh_token].to_s
            }
          }
        end

        def validate_required_params(args:, required:)
          required.each do |param|
            unless args[param].present?
              raise Errors::Authentication::RequestBody::MissingRequestParam, param.to_s
            end
          end
        end

        def resolve_identity(jwt:)
          identity = jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]

          unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
                  @authenticator.claim_mapping
          end

          identity
        end
      end

      module Strategies
        class BaseStrategy
          def initialize(oidc_client:, logger: Rails.logger)
            @oidc_client = oidc_client
            @logger = logger
          end
        end

        class CodeAuthentication < BaseStrategy
          REQUIRED_PARAMETERS = %i[code nonce code_verifier]

          def call(args)
            @oidc_client.exchange_code_for_tokens(
              code: args[:code],
              nonce: args[:nonce],
              code_verifier: args[:code_verifier]
            )
          end
        end

        class RefreshAuthentication < BaseStrategy
          REQUIRED_PARAMETERS = %i[refresh_token nonce]

          def call(args)
            @oidc_client.exchange_refresh_token_for_tokens(
              refresh_token: args[:refresh_token],
              nonce: args[:nonce]
            )
          end
        end
      end
    end
  end
end
