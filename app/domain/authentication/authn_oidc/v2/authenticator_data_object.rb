require 'securerandom'
require 'digest'

module Authentication
  module AuthnOidc
    module V2
      module DataObjects
        class SecurityAttributes
          attr_reader :nonce, :state, :code_verifier

          # Part of the initializer to allow dependency injection.
          # These values need to remain dynamic to ensure security
          def initialize(
            nonce: SecureRandom.hex(25),
            state: SecureRandom.hex(25),
            code_verifier: SecureRandom.hex(25)
          )
            @nonce = nonce
            @state = state
            @code_verifier = code_verifier
          end

          def code_challenge
            Digest::SHA256.base64digest(@code_verifier).tr("+/", "-_").tr("=", "")
          end

          def code_challenge_method
            'S256'
          end
        end
        class Authenticator
          attr_reader(
            :provider_uri,
            :client_id,
            :client_secret,
            :claim_mapping,
            :account,
            :service_id,
            :redirect_uri,
            :response_type
          )

          def initialize(
            provider_uri:,
            client_id:,
            client_secret:,
            claim_mapping:,
            account:,
            service_id:,
            redirect_uri: nil,
            name: nil,
            response_type: 'code',
            provider_scope: nil
          )
            @account = account
            @provider_uri = provider_uri
            @client_id = client_id
            @client_secret = client_secret
            @claim_mapping = claim_mapping
            @response_type = response_type
            @service_id = service_id
            @name = name
            @provider_scope = provider_scope
            @redirect_uri = redirect_uri
          end

          def scope
            (%w[openid email profile] + [*@provider_scope]).uniq.join(' ')
          end

          def name
            @name || @service_id.titleize
          end

          def resource_id
            "#{account}:webservice:conjur/authn-oidc/#{service_id}"
          end
        end
      end
    end
  end
end
