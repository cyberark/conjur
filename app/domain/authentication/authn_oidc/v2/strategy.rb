
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
            jwt, refresh_token = nil, nil
          if args[:refresh_token]
            jwt, refresh_token = @client.get_token_with_refresh_token(
              refresh_token: args[:refresh_token],
              nonce: args[:nonce]
            )
          else
            %i[code nonce code_verifier].each do |param|
              unless args[param].present?
                raise Errors::Authentication::RequestBody::MissingRequestParam, param.to_s
              end
            end
            jwt, refresh_token = @client.get_token_with_code(
              code: args[:code],
              nonce: args[:nonce],
              code_verifier: args[:code_verifier]
            )
          end
          identity = resolve_identity(jwt: jwt)
          unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
                  @authenticator.claim_mapping
          end

          return [identity, {}] if refresh_token.nil?
          [identity, { 'X-OIDC-Refresh-Token' => refresh_token }]
        end

        def resolve_identity(jwt:)
          jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
        end
      end
    end
  end
end
