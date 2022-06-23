module Authentication
  module Handler
    class Handler
      def initialize(
        authenticator_type:,
        role: ::Role,
        resource: ::Resource,
        authn_repo: DB::Repository::AuthenticatorRepository
      )
        @role = role
        @resource = resource
        @authenticator_type = authenticator_type

        # Dynamically load authenticator specific classes
        klass_namespace = case authenticator_type
                          when 'authn-oidc'
                            # 'V2' is a bit of a hack to handle the fact that
                            # the original OIDC authenticator is really a
                            # glorified JWT authenticator.
                            'AuthnOidc::V2'
                          else
                            raise "#{authenticator_type} is not supported"
        end

        @identity_resolver = "Authentication::#{klass_namespace}::ResolveIdentity".constantize
        @strategy = "Authentication::#{klass_namespace}::Strategy".constantize
        @authn_repo = authn_repo.new(
          data_object: "Authentication::#{klass_namespace}::DataObjects::Authenticator".constantize
        )
      end

      def call(parameters:, request_ip:)
        # Load Authenticator policy and values (validates data stored as variables)
        authenticator = @authn_repo.find(
          type: @authenticator_type,
          account: parameters[:account],
          service_id: parameters[:service_id]
        )

        role = @identity_resolver.new.call(
          identity: @strategy.new(
            authenticator: authenticator
          ).callback(
            code: parameters[:code],
            state: parameters[:state]
          ),
          account: parameters[:account],
          allowed_roles: @role.that_can(
            :authenticate,
            @resource[authenticator.resource_id]
          ).all
        )

        raise 'failed to authenticate' unless role

        unless role.valid_origin?(request_ip)
          raise 'IP address is  to authenticate'
        end

        TokenFactory.new.signed_token(
          account: parameters[:account],
          username: role.role_id.split(':').last
        )
      end
    end
  end
end
