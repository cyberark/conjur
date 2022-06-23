module Authentication
  module Handler
    class Handler
      def initialize(
        authenticator_type:,
        role: ::Role,
        resource: ::Resource,
        authn_repo: DB::Repository::AuthenticatorRepository.new
      )
        @role = role
        @resource = resource
        @authn_repo = authn_repo

        case authenticator_type
        when 'authn-oidc'
          # 'V2' is a bit of a hack to handle the fact that the original OIDC authenticator
          # is really a glorified JWT authenticator.
          @data_object = Authentication::AuthnOidc::V2::DataObjects::Authenticator
          @identity_resolver = Authentication::AuthnOidc::V2::ResolveIdentity
        else
          raise "#{authenticator_type} is not supported"
        end

        @type = authenticator_type
      end

      def call(parameters:, request_ip:)
        # Load Authenticator policy and values (validates data stored as variables)
        authenticator = @authn_repo.find(
          type: @type,
          account: parameters[:account],
          service_id: parameters[:service_id]
        )

        role = @identity_resolver.new.call(
          identity: Authentication::AuthnOidc::V2::Strategy.new(
            authenticator: authenticator
          ).callback(
            code: parameters[:code],
            state: parameters[:state],
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
