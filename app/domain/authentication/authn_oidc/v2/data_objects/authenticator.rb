module Authentication
  module AuthnOidc
    module V2
      module DataObjects
        class Authenticator

          REQUIRED_VARIABLES = %i[provider_uri client_id client_secret claim_mapping].freeze
          OPTIONAL_VARIABLES = %i[redirect_uri response_type provider_scope name token_ttl].freeze

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
            provider_scope: nil,
            token_ttl: 'PT8M'
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
            @token_ttl = token_ttl
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

          # Returns the validity duration, in seconds, of an instance's access tokens.
          def token_ttl
            ActiveSupport::Duration.parse(@token_ttl)
          rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
            raise Errors::Authentication::DataObjects::InvalidTokenTTL.new(resource_id, @token_ttl)
          end
        end
      end
    end
  end
end
