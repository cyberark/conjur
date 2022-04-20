module DB
  module Repository
    class AuthenticatorRepository
      def initialize(resource_repository: ::Resource, secret_repository:
            ::Secret)
        @resource_repository = resource_repository
        @secret_repository = secret_repository
      end

      def find(type:, account:, service_id:)
        return nil unless exists?(
          type: type,
          account: account,
          service_id: service_id
        )

        variable_ids = @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:conjur/authn-#{type}/#{service_id}/%"
          )
        ).map(:resource_id)
        variables = @resource_repository.where(
          resource_id: variable_ids
        ).eager(:secrets).all

        args_list = {}.tap do |args|
          args[:account] = account
          args[:service_id] = service_id
          variables.each do |variable|
            args[variable.resource_id.split('/')[-1].underscore.to_sym] = variable.secret.value
          end
        end

        "Authenticator::#{type.camelize}Authenticator".constantize.new(**args_list)
      end

      def exists?(type:, account:, service_id:)
        return @resource_repository
                 .exists?("#{account}:webservice:conjur/authn-#{type}/#{service_id}")
      end
    end
  end
end