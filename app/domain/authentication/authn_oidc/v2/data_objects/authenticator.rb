module Authentication
  module AuthnOidc
    module V2
      module DataObjects
        class Authenticator

          REQUIRED_VARIABLES = %i[provider_uri client_id client_secret claim_mapping].freeze
          OPTIONAL_VARIABLES = %i[redirect_uri response_type provider_scope name].freeze

          attr_reader :provider_uri, :client_id, :client_secret, :claim_mapping, :account
          attr_reader :service_id, :redirect_uri, :response_type

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
            (%w[openid email profile] + [*@provider_scope.to_s.split(' ')]).uniq.join(' ')
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
