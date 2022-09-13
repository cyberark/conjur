# frozen_string_literal: true

require 'dry/schema'

module Authentication
  module AuthnOidc
    module V2
      module DataObjects
        class Authenticator

          CONJUR_VARIABLE_SCHEMA = Dry::Schema.Params do
            required(:provider_uri).filled(:string)
            required(:client_id).filled(:string)
            required(:client_secret).filled(:string)
            required(:claim_mapping).filled(:string)
            optional(:redirect_uri).filled(:string)
            optional(:name).filled(:string)
            optional(:response_type).filled(:string)
            optional(:additional_provider_scope).filled(:string)
          end

          # required
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

          # , :nonce, :state

          def initialize(
            provider_uri:,
            client_id:,
            client_secret:,
            claim_mapping:,
            # nonce:,
            # state:,
            account:,
            service_id:,
            redirect_uri: nil,
            name: nil,
            response_type: 'code',
            additional_provider_scope: nil
          )
            @provider_uri = provider_uri
            @client_id = client_id
            @client_secret = client_secret
            @claim_mapping = claim_mapping
            # @nonce = nonce
            # @state = state
            @account = account
            @service_id = service_id
            @redirect_uri = redirect_uri
            @name = name
            @response_type = response_type
            @additional_provider_scope = additional_provider_scope
          end

          def scope
            (
              %w[openid email profile] +
              @additional_provider_scope.to_s.split(' ')
            ).uniq.join(' ')
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
