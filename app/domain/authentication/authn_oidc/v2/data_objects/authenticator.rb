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

          # rubocop:disable Metrics/ParameterLists
          # rubocop:disable Lint/MissingSuper
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
            token_ttl: '',
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
            @ca_cert = ca_cert

            # Set TTL to 60 minutes by default
            @token_ttl = token_ttl.present? ? token_ttl : 'PT60M'
          end
          # rubocop:enable Metrics/ParameterLists
          # rubocop:enable Lint/MissingSuper

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
