module DB
  module Repository
    class AuthenticatorRepository
      def initialize(resource_repository: ::Resource)
        @resource_repository = resource_repository
      end

      def find_all(type:, account:, role: nil)
        args_list = []
        variables = fetch_authenticators(account: account, type: type, service_id: nil, role: role)
        variables.each do |variable|
          next unless variable.secret

          args = {}
          args[:service_id] = variable.owner_id.split('/')[-1].underscore.to_sym
          args[:account] = account
          args[variable.resource_id.split('/')[-1].underscore.to_sym] =
            variable.secret.value
          args_list.push(args)
        end
        args_list.group_by{|authn| authn[:service_id]}.map do |_, authn|
          "Authenticator::#{type.camelize}Authenticator".constantize.new(**authn.reduce({}, :merge))
        end
      end

      def find(type:, account:, service_id:, role: nil)
        return nil unless exists?(
          type: type,
          account: account,
          service_id: service_id
        )

        variables = fetch_authenticators(account: account, type: type, service_id: service_id, role: role)

        args_list = {}.tap do |args|
          args[:account] = account
          args[:service_id] = service_id
          variables.each do |variable|
            next unless variable.secret

            args[variable.resource_id.split('/')[-1].underscore.to_sym] = variable.secret.value
          end
        end

        "Authenticator::#{type.camelize}Authenticator".constantize.new(**args_list)
      end

      def resources(role:)
        unless role
          return @resource_repository
        end

        @resource_repository.visible_to(role)
      end

      def fetch_authenticators(account:, type:, service_id:, role:)
        puts account, type, service_id, role
        resources(role: role).where(
          Sequel.like(
            :resource_id,
            authn_search(account, type, service_id)
          )
        ).eager(:secrets).all
      end

      def authn_search(account, type, service_id)
        search = "#{account}:variable:conjur/authn-#{type}"
        puts search
        return "#{search}/%" unless service_id

        "#{search}/#{service_id}/%"
      end

      def exists?(type:, account:, service_id:)
        @resource_repository.with_pk("#{account}:webservice:conjur/authn-#{type}/#{service_id}") != nil
      end
    end
  end
end