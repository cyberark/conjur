# module Authentication
#   module AuthnOidc
#     class Authenticator
#       attr_reader :provider_uri, :client_id, :client_secret, :claim_mapping, :nonce, :state, :account

#       def initialize(provider_uri:, client_id:, client_secret:, claim_mapping:, nonce:, state:, account:)
#         @account = account
#         @provider_uri = provider_uri
#         @client_id = client_id
#         @client_secret = client_secret
#         @claim_mapping = claim_mapping
#         @nonce = nonce
#         @state = state
#       end

#       def valid?; end

#       def resource_id; end
#     end
#   end
# end

module DB
  module Repository
    module DataObjects
      class AuthnOidc
      #   REQUIRED_ATTRIBUTES = %i[ provider_uri ...]
      #   OPTIONAL_ATTRIBUTES = %i[ claim_mapping ]
      # end
        attr_reader :provider_uri, :client_id, :client_secret, :claim_mapping, :nonce, :state, :account, :service_id

        def initialize(provider_uri:, client_id:, client_secret:, claim_mapping:, nonce:, state:, account:, service_id:, name: nil)
          @account = account
          @provider_uri = provider_uri
          @client_id = client_id
          @client_secret = client_secret
          @claim_mapping = claim_mapping
          @nonce = nonce
          @state = state
          @service_id = service_id
          @name = name
        end

        def response_type
          # TODO: Add as optional
          'code'
        end

        def scope
          # TODO: Add as optional
          ERB::Util.url_encode('openid profile email')
        end

        def redirect_uri
          # TODO: Add as required
          'http://localhost:3000/authn-oidc/okta-2/cucumber/authenticate'
        end

        def name
          @name || @service_id.titleize
        end

        def valid?; end

        def resource_id
          "#{account}:webservice:conjur/authn-oidc/#{service_id}"
        end

      end
    end

    class AuthenticatorRepository
      def initialize(resource_repository: ::Resource)
        @resource_repository = resource_repository
      end

      def find_all(type:, account:)
        @resource_repository.where{
          Sequel.like(
            :resource_id,
            "#{account}:webservice:conjur/authn-#{type}/%"
          ) &
          Sequel.~(Sequel.like(
            :resource_id,
            "%/status"
          ))
        }.map do |webservice|
          load_authenticator(account: account, id: webservice.id.split(':').last, type: type)
        end.compact
      end

      def find(type:, account:,  service_id:)
        webservice =  @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:webservice:conjur/authn-#{type}/#{service_id}%"
          )
        ).first
        unless webservice
          return
        end

        load_authenticator(account: account, id: webservice.id.split(':').last, type: type)
      end

      def exists?(type:, account:, service_id:)
        @resource_repository.with_pk("#{account}:webservice:conjur/authn-#{type}/#{service_id}") != nil
      end

      private

      def load_authenticator(type:, account:, id:)
        # service_id = id.split('/')[2].underscore.to_sym
        service_id = id.split('/')[2]
        variables = @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:conjur/authn-#{type}/#{service_id}/%"
          )
        ).eager(:secrets).all

        args_list = {}.tap do |args|
          args[:account] = account
          args[:service_id] = service_id
          # id.split('/')[2] # .underscore.to_sym.to_s
          variables.each do |variable|
            # binding.pry
            next unless variable.secret

            # args[variable.resource_id.split('/')[-1].underscore.to_sym] = variable.secret.value
            # binding.pry
            args[variable.resource_id.split('/')[-1].underscore.to_sym] = variable.secret.value
          end
        end
        puts args_list.inspect
        # Authentication::AuthnOidc::Authenticator.new(**args_list)
        begin
          DB::Repository::DataObjects::AuthnOidc.new(**args_list)
        rescue ArgumentError => e
          puts e
          puts "invalid: #{args_list.inspect}"
        end
        # "Authenticator::#{type.camelize}Authenticator".constantize.new(**args_list)
      end
    end
  end
end
