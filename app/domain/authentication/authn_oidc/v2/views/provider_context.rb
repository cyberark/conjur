module Authentication
  module AuthnOidc
    module V2
      module Views
        class ProviderContext
          def initialize(
            client: Authentication::AuthnOidc::V2::Client,
            security_obj: Authentication::AuthnOidc::V2::DataObjects::SecurityAttributes,
            logger: Rails.logger
          )
            @client = client
            @logger = logger
            @security_obj = security_obj
          end

          def call(authenticators:)
            authenticators.map do |authenticator|
              security = @security_obj.new
              client = @client.new(authenticator: authenticator)
              {
                service_id: authenticator.service_id,
                type: 'authn-oidc',
                name: authenticator.name,
                redirect_uri: generate_redirect_url(
                  authorization_endpoint: client.discovery_information.authorization_endpoint,
                  client_id: authenticator.client_id,
                  response_type: authenticator.response_type,
                  scope: authenticator.scope,
                  state: security.state,
                  nonce: security.nonce,
                  code_challenge: security.code_challenge,
                  code_challenge_method: security.code_challenge_method,
                  redirect_uri: authenticator.redirect_uri
                )
              }.merge({
                state: security.state,
                nonce: security.nonce,
                code_verifier: security.code_verifier
              })
            end
          end

          def generate_redirect_url(authorization_endpoint:, client_id:, response_type:, scope:, state:, code_challenge:, code_challenge_method:, nonce:, redirect_uri:)
            params = {
              client_id: client_id,
              response_type: response_type,
              scope: ERB::Util.url_encode(scope),
              state: state,
              code_challenge: code_challenge,
              code_challenge_method: code_challenge_method,
              nonce: nonce,
              redirect_uri: ERB::Util.url_encode(redirect_uri)
            }.map { |key, value| "#{key}=#{value}" }.join("&")

            "#{authorization_endpoint}?#{params}"
          end
        end
      end
    end
  end
end
