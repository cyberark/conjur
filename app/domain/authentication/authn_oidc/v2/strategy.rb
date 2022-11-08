# frozen_string_literal: true

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
          strategy = if args.key?(:refresh_token)
            Strategies::RefreshAuthentication
          elsif args.key?(:code)
            Strategies::CodeAuthentication
          else
            raise 'Must provide either a refresh token or code'
          end

          # Ensure correct arguements are available for the strategy
          validate_required_arguments(
            args: args,
            required_parameters: strategy.const_get(:REQUIRED_PARAMETERS)
          )

          # Resolve identity depending on strategy
          identity = resolve_identity(
            jwt: strategy.new(
              oidc_client: Authentication::AuthnOidc::V2::Client.new(
                authenticator: @authenticator
              )
            ).call(args)
          )

          # Raise exception if JWT does not include the intended identity claim
          unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
                  @authenticator.claim_mapping
          end
          identity
        end

        def resolve_identity(jwt:)
          jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
        end

        def validate_required_arguments(args:, required_parameters:)
          required_parameters.each do |param|
            unless args[param].present?
              raise Errors::Authentication::RequestBody::MissingRequestParam, param.to_s
            end
          end
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
          REQUIRED_PARAMETERS = %i[code nonce code_verifier].freeze

          def call(args)
            @oidc_client.exchange_code_for_identity_token(
              code: args[:code],
              nonce: args[:nonce],
              code_verifier: args[:code_verifier],
              refresh: true
            )
          end
        end

        class RefreshAuthentication < BaseStrategy
          REQUIRED_PARAMETERS = %i[refresh_token nonce].freeze

          def call(args)
            @oidc_client.get_token_with_refresh_token(
              refresh_token: args[:refresh_token],
              nonce: args[:nonce]
            )
          end
        end

        # module Common
        #   def initialize(
        #     authenticator:,
        #     client: Authentication::AuthnOidc::V2::Client,
        #     logger: Rails.logger
        #   )
        #     @authenticator = authenticator
        #     @client = client.new(authenticator: authenticator)
        #     @logger = logger
        #   end

        #   def validate_args(args:, required:)
        #     if args[:code] && args[:refresh_token]
        #       raise Errors::Authentication::RequestBody::MultipleXorRequestParams.new('code', 'refresh_token')
        #     end

        #     required.each do |param|
        #       unless args[param].present?
        #         raise Errors::Authentication::RequestBody::MissingRequestParam, param.to_s
        #       end
        #     end
        #   end

        #   def authenticate_with_oidc(&block)
        #     jwt, refresh_token = block.call

        #     identity = resolve_identity(jwt: jwt)
        #     unless identity.present?
        #       raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
        #             @authenticator.claim_mapping
        #     end

        #     return [identity, {}] if refresh_token.nil?
        #     [identity, { 'X-OIDC-Refresh-Token' => refresh_token }]
        #   end

        #   def resolve_identity(jwt:)
        #     jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
        #   end
        # end

        # class AuthzCode
        #   include Common

        #   def callback(args)
        #     validate_args(args: args, required: %i[code nonce code_verifier])
        #     authenticate_with_oidc do
        #       @client.get_token_with_code(
        #         code: args[:code],
        #         nonce: args[:nonce],
        #         code_verifier: args[:code_verifier]
        #       )
        #     end
        #   end
        # end

        # class RefreshToken
        #   include Common

        #   def callback(args)
        #     validate_args(args: args, required: %i[refresh_token nonce])
        #     authenticate_with_oidc do
        #       @client.get_token_with_refresh_token(
        #         refresh_token: args[:refresh_token],
        #         nonce: args[:nonce]
        #       )
        #     end
        #   end
        # end

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
