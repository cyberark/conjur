# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class Strategy
        REQUIRED_PARAMS = %i[code nonce].freeze
        ALLOWED_PARAMS = (REQUIRED_PARAMS + %i[code_verifier]).freeze

        def initialize(
          authenticator:,
          client: Authentication::AuthnOidc::V2::Client,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @client = client.new(authenticator: authenticator)
          @logger = logger
        end

        def callback(parameters:, request_body: nil)
          # NOTE: `code_verifier` param is optional
          REQUIRED_PARAMS.each do |param|
            unless parameters[param].present?
              raise Errors::Authentication::RequestBody::MissingRequestParam, param.to_s
            end
          end

          identity = resolve_identity(
            jwt: @client.callback_with_temporary_cert(
              code: args[:code],
              nonce: args[:nonce],
              code_verifier: args[:code_verifier],
              cert_string: @authenticator.ca_cert
            )
          )
          unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty.new(
              @authenticator.claim_mapping,
              "claim-mapping"
            )
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
