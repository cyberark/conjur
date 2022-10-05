
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
          # TODO: Check that `code`, `code_verifier` and `nonce` attributes are present
          unless args[:code].present?
            raise Errors::Authentication::RequestBody::MissingRequestParam, 'code'
          end
          unless args[:nonce].present?
            raise Errors::Authentication::RequestBody::MissingRequestParam, 'nonce'
          end
          unless args[:code_verifier].present?
            raise Errors::Authentication::RequestBody::MissingRequestParam, 'code_verifier'
          end

          identity = resolve_identity(
            jwt: @client.callback(
              code: args[:code],
              nonce: args[:nonce],
              code_verifier: args[:code_verifier]
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
