module Authentication
  module AuthnOidc
    module PkceSupportFeature
      class Strategy
        def initialize(
          authenticator:,
          client: Authentication::AuthnOidc::PkceSupportFeature::Client,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @client = client.new(authenticator: authenticator)
          @logger = logger
        end

        def callback(args)
          %i[code nonce code_verifier].each do |param|
            unless args[param].present?
              raise Errors::Authentication::RequestBody::MissingRequestParam, param.to_s
            end
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
