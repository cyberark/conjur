# frozen_string_literal: true

module Authentication
  class Handler
    def initialize(
      authenticator_type:,
      role: ::Role,
      resource: ::Resource,
      authn_repo: DB::Repository::AuthenticatorRepository,
      namespace_selector: Authentication::Util::NamespaceSelector
    )
      @role = role
      @resource = resource
      @authenticator_type = authenticator_type

      # Dynamically load authenticator specific classes
      namespace = namespace_selector.select(
        authenticator_type: authenticator_type
      )

      @identity_resolver = "#{namespace}::ResolveIdentity".constantize
      @strategy = "#{namespace}::Strategy".constantize
      @authn_repo = authn_repo.new(
        data_object: "#{namespace}::DataObjects::Authenticator".constantize
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
        ).callback(parameters),
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
