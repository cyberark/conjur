module Authenticator
  module Repository
    class AuthenticatorInterface
      def find(service_id:)
        raise NotImplementedError
      end

      def create(authenticator:)
        raise NotImplementedError
      end

      def update(authenticator:)
        raise NotImplementedError
      end

      def destroy(service_id:)
        raise NotImplementedError
      end

      def policy_template(service_id:)
        <<~TEMPLATE
        - !policy
          id: #{service_id}
          body:
          - !webservice

          - !variable provider_uri
          - !variable client_id
          - !variable client_secret
          - !variable claim_mapping
          - !variable state
          - !variable nonce

          - !group
            id: authenticatable
            annotations:
              description: Users who can authenticate using this authenticator

          - !permit
            role: !group authenticatable
            privilege: [ read, authenticate ]
            resource: !webservice
        TEMPLATE
      end
    end

    class Oidc < AuthenticatorInterface
      def initialize(account:, loader: ::Policy::LoadPolicy.new, resource: ::Resource, secret: ::Secret)
        super()
        @account = account
        @policy_loader = loader
        @resource = resource
        @secret = secret
      end

      def find(service_id:)
        variable_ids = @resource.where(Sequel.like(:resource_id, "#{@account}:variable:conjur/authn-oidc/#{service_id}/%")).map(:resource_id)
        variables = @resource.where(resource_id: variable_ids).eager(:secrets).all
        args_list = {}.tap do |args|
          args[:service_id] = service_id
          variables.each do |variable|
            args[variable.resource_id.split('/')[-1].underscore.to_sym] = variable.secret.value
          end
        end
        Authenticator::Repository::Schema::Oidc.new(**args_list)
      end

      # Policy load fails unless it is loaded via the Policy API. I have no idea why. In the future,
      # it would be ideal to add a generic repository structure to create types.
      def create(authenticator:)
        role = Role["#{@account}:user:admin"]
        resource = Resource["#{@account}:policy:conjur/authn-oidc"]
        Loader::Types.find_or_create_root_policy(@account)
        Policy::LoadPolicy.new(loader_class: Loader::CreatePolicy).(
          delete_permitted: false,
          action: :create,
          resource: resource,
          policy_text: policy_template(service_id: authenticator.service_id),
          current_user: role,
          client_ip: '127.0.0.1'
        )
        update(authenticator: authenticator)
      end

      def update(authenticator:)
        authenticator.variables.each do |variable|
          @secret.create(
            resource_id: [
              @account,
              'variable',
              "conjur/authn-oidc/#{authenticator.service_id}/#{variable.to_s.dasherize}"
            ].join(':'),
            value: authenticator.send(variable)
          )
        end
      end

      def destroy(service_id:)
      end
    end

    module Schema
      class Base
        def variables
          instance_variables.map {|variable| variable.to_s.gsub(/@/, '').to_sym } - [:service_id]
        end
      end

      class Oidc < Base
        attr_reader :service_id, :provider_uri, :client_id, :client_secret, :claim_mapping, :state, :nonce

        def initialize(service_id:, provider_uri:, client_id:, client_secret:, claim_mapping:, state: SecureRandom.hex(16), nonce: SecureRandom.hex(16))
        # def initialize(service_id:, provider_uri:, id_token_user_property:)
          super()
          @service_id = service_id
          @provider_uri = provider_uri
          # @id_token_user_property = id_token_user_property

          @client_id = client_id
          @client_secret = client_secret
          @claim_mapping = claim_mapping
          @state = state
          @nonce = nonce
        end
      end
    end
  end
end
