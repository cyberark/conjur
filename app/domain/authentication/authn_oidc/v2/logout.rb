# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class Logout
        REQUIRED_PARAMETERS = %i[refresh_token nonce state]
        OPTIONAL_PARAMETERS = %i[post_logout_redirect_uri]

        def initialize(
          authenticator:,
          client: Authentication::AuthnOidc::V2::Client,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @client = client.new(authenticator: authenticator)
          @logger = logger
        end

        def callback(args)
          REQUIRED_PARAMETERS.each do |param|
            unless args[param].present?
              raise Errors::Authentication::RequestBody::MissingRequestParam, param.to_s
            end
          end

          id_token_and_logout_uri = @client.exchange_refresh_token_for_logout_uri(
            refresh_token: args[:refresh_token],
            nonce: args[:nonce],
            state: args[:state],
            post_logout_redirect_uri: args[:post_logout_redirect_uri]
          )

          {
            :identity => resolve_identity(jwt: id_token_and_logout_uri[:id_token]),
            :logout_uri => id_token_and_logout_uri[:logout_uri].to_s
          }
        end

        def resolve_identity(jwt:)
          identity = jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]

          unless identity.present?
            raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty
                  @authenticator.claim_mapping
          end

          identity
        end
      end
    end
  end
end
