# frozen_string_literal: true

module Authentication
  module Handler
    class StatusHandler
      # Handles prerequisite validation
      class Prerequisites < Dry::Validation::Contract
        option :available_authenticators
        option :resource
        option :authenticator_type

        params do
          required(:account).filled(:string)
          # Service ID is optional only so that we can throw a custom error
          optional(:service_id).filled(:string)
        end

        # Is service_id present?
        rule(:service_id) do
          unless values[:service_id].present?
            failed_response(key: key, error: Errors::Authentication::AuthnJwt::ServiceIdMissing)
          end
        end

        # Verify authenticator is whitelisted
        rule(:service_id) do
          identifier = authenticator_identifier(values[:service_id])

          unless available_authenticators.enabled_authenticators.include?(identifier)
            failed_response(
              key: key,
              error: Errors::Authentication::Security::AuthenticatorNotWhitelisted.new(identifier)
            )
          end
        end

        # Verify webservices exists for authenticator
        rule(:account, :service_id) do
          identifier = "conjur/#{authenticator_identifier(values[:service_id])}"

          webservice = "#{values[:account]}:webservice:#{identifier}"
          if resource[webservice].blank?
            failed_response(
              key: key,
              error: Errors::Authentication::Security::WebserviceNotFound.new(identifier, values[:account])
            )
          end
        end

        # Verify webservices exists for authenticator status
        rule(:account, :service_id) do
          identifier = "#{authenticator_identifier(values[:service_id])}/status"
          webservice = "#{values[:account]}:webservice:conjur/#{identifier}"

          if resource[webservice].blank?
            failed_response(
              key: key,
              error: Errors::Authentication::Security::WebserviceNotFound.new(identifier, values[:account])
            )
          end
        end

        private

        def authenticator_identifier(service_id)
          "#{authenticator_type}/#{service_id}"
        end

        def failed_response(error:, key:)
          key.failure(exception: error, text: error.message)
        end
      end

      def initialize(
        authenticator_type:,
        role: ::Role,
        resource: ::Resource,
        authn_repo: DB::Repository::AuthenticatorRepository,
        namespace_selector: Authentication::Util::NamespaceSelector,
        available_authenticators: Authentication::InstalledAuthenticators
      )
        @authenticator_type = authenticator_type
        @available_authenticators = available_authenticators
        @role = role
        @resource = resource

        # Dynamically load authenticator specific classes
        namespace = namespace_selector.select(
          authenticator_type: authenticator_type
        )

        @strategy = "#{namespace}::Strategy".constantize
        @authn_repo = authn_repo.new(
          data_object: "#{namespace}::DataObjects::Authenticator".constantize
        )
      end

      def call(parameters:, request_ip:, role:)
        validate_rerequisites({ request_ip: request_ip }.merge(parameters))

        role_permitted?(
          account: parameters[:account],
          service_id: parameters[:service_id],
          role: role
        )

        verify_status(account: parameters[:account], service_id: parameters[:service_id])
      end

      private

      def validate_rerequisites(args)
        result = Prerequisites.new(
          available_authenticators: @available_authenticators,
          resource: @resource,
          authenticator_type: @authenticator_type
        ).call(**args)

        raise(result.errors.first.meta[:exception]) unless result.success?
      end

      def role_permitted?(account:, service_id:, role:)
        webservice_id = "#{account}:webservice:conjur/#{@authenticator_type}/#{service_id}/status"
        status_webservice = @resource[webservice_id]
        return if role.allowed_to?(:read, status_webservice)

        raise Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
          role.identifier,
          :read,
          status_webservice.id
        )
      end

      def verify_status(account:, service_id:)
        unless (authenticator = @authn_repo.find(type: @authenticator_type, account: account, service_id: service_id))
          raise(
            Errors::Conjur::RequestedResourceNotFound,
            "Unable to find authenticator with account: #{account} and service-id: #{service_id}"
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
