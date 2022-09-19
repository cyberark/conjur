
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
          # TODO: Check that `code` and `state` attributes are present
          raise Errors::Authentication::AuthnOidc::StateMismatch unless args[:state] == @authenticator.state

          if args[:code].nil?
            jwt, refresh_token = @client.refresh(refresh_token: args[:refresh_token])
          else
            jwt, refresh_token = @client.callback(code: args[:code])
          end

          identity = resolve_identity(
            jwt: jwt,
            claim_mapping: @authenticator.claim_mapping
          )
          return identity, refresh_token
        end

        def resolve_identity(jwt:, claim_mapping:, logger: Rails.logger)
          identity = jwt.raw_attributes.with_indifferent_access[claim_mapping]
          unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty, claim_mapping
          end
          identity
        end
      end
    end
  end
end
