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
          @logger.info("-- args: #{args.inspect}")
          # TODO: Check that `code` and `state` attributes are present
          raise Errors::Authentication::AuthnOidc::StateMismatch unless args[:state] == @authenticator.state

          identity = resolve_identity(
            jwt: @client.callback(
              code: args[:code]
            )
          )
          unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
                  @authenticator.claim_mapping
          end
          identity
        end

        def resolve_identity(jwt:)
          @logger.info(jwt.raw_attributes.inspect)
          jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
        end
      end
    end
  end
end
