require 'digest'
require 'securerandom'

module Authentication
  module AuthnOidc
    module V2
      module Views
        class ProviderContext
          def initialize(
            client: Authentication::AuthnOidc::V2::Client,
            random: SecureRandom,
            logger: Rails.logger
          )
            @client = client
            @random = random
            @logger = logger
          end

          def call(authenticators:)
            # Generate random values for nonce and verifier
            nonce = @random.hex(25)
            verifier = @random.hex(25)

            authenticators.map do |authenticator|
              {
                service_id: authenticator.service_id,
                type: 'authn-oidc',
                name: authenticator.name,
                nonce: nonce,
                code_verifier: verifier,
                redirect_uri: redirect_url(
                  oidc_url: @client.new(authenticator: authenticator).discovery_information.authorization_endpoint,
                  authenticator: authenticator,
                  nonce: nonce,
                  code_verifier: verifier
                )
              }
            end
          end

          def redirect_url(oidc_url:, authenticator:, nonce:, code_verifier:)
            params = {
              client_id: authenticator.client_id,
              response_type: authenticator.response_type,
              scope: ERB::Util.url_encode(authenticator.scope),
              nonce: nonce,
              code_challenge: Digest::SHA256.base64digest(code_verifier).tr("+/", "-_").tr("=", ""),
              code_challenge_method: 'S256'
            }
            # Keycload doesn't allow the redirect uri as a parameter
            if authenticator.redirect_uri.present?
              params[:redirect_uri] = ERB::Util.url_encode(authenticator.redirect_uri)
            end

            param_args = params.map { |key, value| "#{key}=#{value}" }.join("&")

            "#{oidc_url}?#{param_args}"
          end
        end
      end
    end
  end
end
