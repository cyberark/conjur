# frozen_string_literal: true

require 'dry/schema'

module Authentication
  module AuthnOidc
    module V2
      class Strategy
        SCHEMA = Dry::Schema.Params do
          required(:nonce).filled(:string)
          required(:code).filled(:string)
          required(:code_verifier).filled(:string)
        end

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
        def callback(code:, nonce:, code_verifier:)
          # TODO: Check that `code` and `state` attributes are present
          # raise Errors::Authentication::AuthnOidc::StateMismatch unless args[:state] == @authenticator.state

          identity = resolve_identity(
            jwt: @client.validate_code(
              code: code,
              nonce: nonce,
              code_verifier: code_verifier
            )
          )
          unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
                  @authenticator.claim_mapping
          end
          identity
        end

        def resolve_identity(jwt:)
          jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
        end
      end
    end
  end
end
