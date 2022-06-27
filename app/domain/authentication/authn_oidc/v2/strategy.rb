
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
          raise 'State is different' if args[:state] != @authenticator.state

          resolve_identity(
            jwt: @client.callback(
              code: args[:code]
            )
          )
        end

        def resolve_identity(jwt:)
          @logger.info(jwt.raw_attributes.inspect)
          jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
        end

      end
    end
  end
end
