module Authentication
  module AuthnOidc
    module V2
      # class Strategy
      module Strategies
        class Utilities
          def self.resolve_identity(jwt:, claim_mapping:, logger: Rails.logger)
            logger.debug("claim mapping: #{claim_mapping}")
            logger.debug("jwt: #{jwt.raw_attributes.inspect}")

            identity = jwt.raw_attributes.with_indifferent_access[claim_mapping]
            unless identity.present?
              raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty, claim_mapping
            end

            logger.debug("resolved identity: #{identity}")
            identity
          end
        end

        # Looks up an identity based on a provided JWT token.
        class Token
          def initialize(
            authenticator:,
            client: Authentication::AuthnOidc::V2::Client,
            logger: Rails.logger,
            utilities: Utilities
          )
            @authenticator = authenticator
            @client = client.new(authenticator: authenticator)
            @logger = logger
            @utilities = utilities
          end

          # Don't love this name...
          def callback(args)
            # raise if args are empty... it means we don't have a token
            @utilities.resolve_identity(
              jwt: @client.validate_token(token: args),
              claim_mapping: @authenticator.claim_mapping
            )
          end
        end

        # Looks up an identity based on a provided OIDC Code.
        class Code
          def initialize(
            authenticator:,
            client: Authentication::AuthnOidc::V2::Client,
            logger: Rails.logger,
            utilities: Utilities
          )
            @authenticator = authenticator
            @client = client.new(authenticator: authenticator)
            @logger = logger
            @utilities = utilities
          end

          # Don't love this name...
          def callback(args)
            @logger.info("-- args: #{args.inspect}")
            # Check we have our required parameters
            raise Errors::Authentication::RequestBody::MissingRequestParam, args[:code] unless args[:code]
            raise Errors::Authentication::RequestBody::MissingRequestParam, args[:state] unless args[:state]

            # Ensure state matches the configured state
            raise Errors::Authentication::AuthnOidc::StateMismatch unless args[:state] == @authenticator.state

            @utilities.resolve_identity(
              jwt: @client.validate_code(
                code: args[:code]
              ),
              claim_mapping: @authenticator.claim_mapping
            )
          end
        end
      end
    end
  end
end
