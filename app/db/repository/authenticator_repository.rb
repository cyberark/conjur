module DB
  module Repository
    class AuthenticatorRepository
      def initialize(resource_repository: ::Resource)
        @resource_repository = resource_repository
      end

      def find_all(type:, account:)
        @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:webservice:conjur/authn-#{type}%"
          )
        ).map do |webservice|
          load_authenticator(account: account, id: webservice.id.split(':').last, type: type)
        end
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
        service_id = id.split('/')[-1].underscore.to_sym
        variables = @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:conjur/authn-#{type}/#{service_id}/%"
          )
        ).eager(:secrets).all

        args_list = {}.tap do |args|
          args[:account] = account
          args[:service_id] = id.split('/')[-1].underscore.to_sym.to_s
          variables.each do |variable|
            next unless variable.secret

            args[variable.resource_id.split('/')[-1].underscore.to_sym] = variable.secret.value
          end
        end

        "Authenticator::#{type.camelize}Authenticator".constantize.new(**args_list)
      end
    end
  end
end