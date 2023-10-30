# frozen_string_literal: true

module DB
  module Repository
    # This class is responsible for loading the variables associated with a
    # particular type of authenticator. Each authenticator requires a Data
    # Object and Data Object Contract (for validation). Data Objects that
    # fail validation are not returned.
    #
    # This class includes two public methods:
    #   - `find_all` - returns all available authenticators of a specified type
    #     from an account
    #   - `find` - returns a single authenticator based on the provided type,
    #     account, and service identifier.
    #
    class AuthenticatorRepository
      def initialize(
        resource_repository: ::Resource,
        available_authenticators: Authentication::InstalledAuthenticators,
        logger: Rails.logger
      )
        @resource_repository = resource_repository
        @available_authenticators = available_authenticators
        @logger = logger

        @success = ::SuccessResponse
        @failure = ::FailureResponse
      end

      def find_all(type:, account:)
        authenticators = authenticator_webservices(type: type, account: account).map do |webservice|
          service_id = service_id_from_resource_id(webservice.id)
          begin
            load_authenticator_variables(account: account, service_id: service_id, type: type)
          rescue => e
            @logger.info("failed to load #{type} authenticator '#{service_id}' do to validation failure: #{e.message}")
            nil
          end
        end.compact
        @success.new(authenticators)
      end

      def find(type:, account:, service_id: nil, &block)
        identifier = [type, service_id].compact.join('/')

        webservice = @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:webservice:conjur/#{identifier}"
          )
        ).first
        unless webservice
          return @failure.new(
            "Failed to find a webservice: '#{account}:webservice:conjur/#{identifier}'",
            exception: Errors::Authentication::Security::WebserviceNotFound.new(identifier, account)
          )
        end

        begin
          @success.new(
            load_authenticator_variables(
              account: account,
              service_id: service_id,
              type: type
            )
          )
        rescue => e
          @failure.new(
            e.message,
            exception: e,
            level: :debug
          )
        end
      end

      private

      def authenticator_webservices(type:, account:)
        @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:webservice:conjur/#{type}/%"
          )
        ).all.select do |webservice|
          # Querying for the authenticator webservice above includes the webservices
          # for the authenticator status. The filter below removes webservices that
          # don't match the authenticator policy.
          webservice.id.split(':').last.match?(%r{^conjur/#{type}/[\w\-_]+$})
        end
      end

      def service_id_from_resource_id(id)
        full_id = id.split(':').last
        full_id.split('/')[2]
      end

      def load_authenticator_variables(type:, account:, service_id:)
        identifier = [type, service_id].compact.join('/')
        variables = @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:conjur/#{identifier}/%"
          )
        ).eager(:secrets).all
        {}.tap do |args|
          args[:account] = account
          args[:service_id] = service_id
          variables.each do |variable|
            # If variable exists but does not have a secret, set the value to an empty string.
            # This is used downstream for validating if a variable has been set or not, and thus,
            # what error to raise.
            value = variable.secret ? variable.secret.value : ''
            args[variable.resource_id.split('/')[-1].underscore.to_sym] = value
          end
        end
      end
    end
  end
end
