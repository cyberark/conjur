module Authentication
  module AuthnOidc
    module V2
      module DataObjects
        class Authenticator

          # required
          attr_reader :provider_uri, :client_id, :client_secret, :claim_mapping, :nonce, :state, :account
          attr_reader :service_id, :redirect_uri

          # optional
          attr_reader :name

          def initialize(
            provider_uri:,
            client_id:,
            client_secret:,
            claim_mapping:,
            nonce:,
            state:,
            account:,
            service_id:,
            redirect_uri:,
            name: nil,
            provider_scope: ['email']
          )
            @account = account
            @provider_uri = provider_uri
            @client_id = client_id
            @client_secret = client_secret
            @claim_mapping = claim_mapping
            @nonce = nonce
            @state = state
            @service_id = service_id
            @name = name
            @provider_scope = provider_scope
            @redirect_uri = redirect_uri
          end

          def response_type
            # TODO: Add as optional
            'code'
          end

          def scope
            ERB::Util.url_encode(
              (%w[openid profile] + [*@provider_scope]).join(' ')
            )
          end

          def redirect_uri
            # TODO: Add as required
            'http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate'
          end

          def name
            @name || @service_id.titleize
          end

          def resource_id
            "#{account}:webservice:conjur/authn-oidc/#{service_id}"
          end

          def oidc_redirect
            params = {
              client_id: client_id,
              response_type: response_type,
              scope: ERB::Util.url_encode(scope),
              state: state,
              nonce: nonce,
              redirect_uri: ERB::Util.url_encode(redirect_uri)
            }.map { |key, value| "#{key}=#{value}" }.join("&")

            "#{provider_uri}?#{params}"
          end
        end
      end
    end
  end
end
