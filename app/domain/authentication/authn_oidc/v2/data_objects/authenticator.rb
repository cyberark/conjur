module Authentication
  module AuthnOidc
    module V2
      module DataObjects
        class Authenticator < Authentication::Base::DataObject

          REQUIRES_ROLE_ANNOTIONS = false

          attr_reader(
            :provider_uri,
            :client_id,
            :client_secret,
            :claim_mapping,
            :account,
            :service_id,
            :redirect_uri,
            :response_type,
            :ca_cert
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
            provider_scope: nil,
            token_ttl: 'PT60M',
            ca_cert: nil
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

            # If variable is present but not set, token_ttl will come
            # through as an empty string.
            @token_ttl = token_ttl.present? ? token_ttl : 'PT60M'
            @ca_cert = ca_cert
          end

          def scope
            (%w[openid email profile] + [*@provider_scope.to_s.split(' ')]).uniq.join(' ')
          end

          def name
            @name || @service_id.titleize
          end

        end
      end
    end
  end
end
