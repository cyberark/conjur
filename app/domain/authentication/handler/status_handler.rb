# frozen_string_literal: true

module Authentication
  module Handler
    class StatusHandler
      def initialize(
        authenticator_type:,
        role: ::Role,
        resource: ::Resource,
        authn_repo: DB::Repository::AuthenticatorRepository,
        namespace_selector: Authentication::Util::NamespaceSelector,
        available_authenticators: Authentication::InstalledAuthenticators,
        logger: Rails.logger,
        audit_logger: ::Audit.logger
      )
        @authenticator_type = authenticator_type
        @available_authenticators = available_authenticators
        @role = role
        @resource = resource
        @logger = logger
        @audit_logger = audit_logger

        # Dynamically load authenticator specific classes
        namespace = namespace_selector.select(
          authenticator_type: authenticator_type
        )

        @strategy = "#{namespace}::Strategy".constantize
        @authn_repo = authn_repo.new(
          data_object: "#{namespace}::DataObjects::Authenticator".constantize,
          contract: "#{namespace}::DataObjects::AuthenticatorContract".constantize.new
        )
      end

      def call(parameters:, request_ip:, role:)
        # verify authenticator is whitelisted....
        unless @available_authenticators.enabled_authenticators.include?("#{parameters[:authenticator]}/#{parameters[:service_id]}")
          raise Errors::Authentication::Security::AuthenticatorNotWhitelisted, "#{parameters[:authenticator]}/#{parameters[:service_id]}"
        end

        # Verify request IP is valid
        # TODO: this really should be happening upstream
        unless role.valid_origin?(request_ip)
          raise Errors::Authentication::InvalidOrigin
        end

        unless parameters[:service_id].present?
          # TODO: feels like this should include the service_id...
          raise Errors::Authentication::AuthnJwt::ServiceIdMissing
        end

        # Verify webservices exist
        authenticator_webservice = "#{parameters[:account]}:webservice:conjur/#{@authenticator_type}/#{parameters[:service_id]}"
        if @resource[authenticator_webservice].blank?
          raise Errors::Authentication::Security::WebserviceNotFound, authenticator_webservice
        end

        unless (status_webservice = @resource["#{authenticator_webservice}/status"])
          raise Errors::Authentication::Security::WebserviceNotFound, "#{@authenticator_type}/#{parameters[:service_id]}/status"
        end

        # Verify role is allowed to use the Status endpoint
        unless role.allowed_to?(:read, status_webservice)
          raise Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
            role.identifier,
            :read,
            status_webservice.id
          )
        end

        # Load Authenticator policy and values (validates data stored as variables)
        unless (authenticator = @authn_repo.find(type: @authenticator_type, account: parameters[:account], service_id: parameters[:service_id]))
          raise(
            Errors::Conjur::RequestedResourceNotFound,
            "Unable to find authenticator with account: #{parameters[:account]} and service-id: #{parameters[:service_id]}"
          )
        end

        # Run checks on authenticator strategy
        @strategy.new(
          authenticator: authenticator
        ).verify_status
      end
    end
  end
end
