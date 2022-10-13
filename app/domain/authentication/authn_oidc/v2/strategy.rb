
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
          if args.key?(:jwt)
            oidc_jwt, claims = @client.validate_jwt(jwt: args[:jwt], nonce: args[:nonce])
          else
            %i[code nonce code_verifier].each do |param|
              unless args[param].present?
                raise Errors::Authentication::RequestBody::MissingRequestParam, param.to_s
              end
            end

            oidc_jwt, claims = @client.callback(
              code: args[:code],
              nonce: args[:nonce],
              code_verifier: args[:code_verifier]
            )
          end
          identity = resolve_identity(jwt: oidc_jwt)
          unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
                  @authenticator.claim_mapping
          end
          return identity, claims
        end

        def resolve_identity(jwt:)
          jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
        end
      end
    end
  end
end
