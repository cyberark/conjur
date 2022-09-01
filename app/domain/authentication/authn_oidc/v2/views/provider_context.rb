module Authentication
  module AuthnOidc
    module V2
      module Views
        class ProviderContext
          def initialize(
            client: Authentication::AuthnOidc::V2::Client,
            logger: Rails.logger
          )
            @client = client
            @logger = logger
          end

          def call(authenticators:)
            authenticators.map do |authenticator|
              state_nonce_code_challenge_values = state_nonce_challenge
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
                  state: state_nonce_code_challenge_values[:state],
                  nonce: state_nonce_code_challenge_values[:nonce],
                  code_verifier: state_nonce_code_challenge_values[:code_verifier],
                  redirect_uri: authenticator.redirect_uri
                  # @client.new(authenticator: authenticator),
                  # client_id:
                  # authenticator: authenticator
                )
              }.merge(state_nonce_code_challenge_values)
            end
          end

          def state_nonce_challenge
            {
              state: SecureRandom.hex(25),
              nonce: SecureRandom.hex(30),
              code_verifier: SecureRandom.hex(35)
            }
          end

          def generate_redirect_url(authorization_endpoint:, client_id:, response_type:, scope:, state:, code_verifier:, nonce:, redirect_uri:)
            # code_verifier = 'f387301683cb91e03f3f25af45ed180293a54541d314252665'
            params = {
              client_id: client_id,
              response_type: response_type,
              scope: ERB::Util.url_encode(scope),
              state: state,
              code_challenge: Digest::SHA256.base64digest(code_verifier).tr("+/", "-_").tr("=", ""),
              code_challenge_method: 'S256',
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
