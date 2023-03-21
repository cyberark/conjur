# frozen_string_literal: true

require 'securerandom'
require 'digest'

module Authentication
  module AuthnOidc
    module V2
      module Views
        class ProviderContext
          def initialize(
            client: Authentication::AuthnOidc::V2::Client,
            digest: Digest::SHA256,
            random: SecureRandom,
            logger: Rails.logger
          )
            @client = client
            @logger = logger
            @digest = digest
            @random = random
          end

          def call(authenticators:)
            authenticators.map do |authenticator|
              begin
                nonce = @random.hex(25)
                code_verifier = @random.hex(25)
                code_challenge = @digest.base64digest(code_verifier).tr("+/", "-_").tr("=", "")
                {
                  service_id: authenticator.service_id,
                  type: 'authn-oidc',
                  name: authenticator.name,
                  nonce: nonce,
                  code_verifier: code_verifier,
                  redirect_uri: generate_redirect_url(
                    client: @client.new(authenticator: authenticator),
                    authenticator: authenticator,
                    nonce: nonce,
                    code_challenge: code_challenge
                  )
                }
              rescue Errors::Authentication::OAuth::ProviderDiscoveryFailed,
                Errors::Authentication::OAuth::ProviderDiscoveryTimeout
                @logger.warn("Authn-OIDC '#{authenticator.service_id}' provider-uri: '#{authenticator.provider_uri}' is unreachable")
                nil
              end
            end.compact
          end

          def generate_redirect_url(client:, authenticator:, nonce:, code_challenge:)
            params = {
              client_id: authenticator.client_id,
              response_type: authenticator.response_type,
              scope: ERB::Util.url_encode(authenticator.scope),
              nonce: nonce,
              code_challenge: code_challenge,
              code_challenge_method: 'S256',
              redirect_uri: ERB::Util.url_encode(authenticator.redirect_uri)
            }
            formatted_params = params.map { |key, value| "#{key}=#{value}" }.join("&")

            "#{client.discovery_information.authorization_endpoint}?#{formatted_params}"
          end
        end
      end
    end
  end
end
