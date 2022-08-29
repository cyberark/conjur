module Authentication
  module AuthnOidc
    module V2
      class Strategy

        REQUIRED_FIELDS = %i[code nonce code_verifier].freeze

        def initialize(
          authenticator:,
          client: Authentication::AuthnOidc::V2::Client,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @client = client.new(authenticator: authenticator)
          @logger = logger
        end

        def validate_required_fields(parameters)
          REQUIRED_FIELDS.each do |field|
            next if parameters.key?(field) && parameters[field].present?

            raise(Errors::Authentication::RequestBody::MissingRequestParam, field)
          end
        end

        # Don't love this name...
        def callback(args)
          @logger.info("-- args: #{args.inspect}")
          # Check we have our required parameters
          validate_required_fields(args)

          resolve_identity(
            jwt: @client.validate_code(
              code: args[:code],
              nonce: args[:nonce],
              code_verifier: args[:code_verifier]
            ),
            claim_mapping: @authenticator.claim_mapping
          )
        end

        def resolve_identity(jwt:, claim_mapping:, logger: Rails.logger)
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
    end
  end
end
