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
        data_object:,
        validations: nil,
        resource_repository: ::Resource,
        logger: Rails.logger
      )
        @resource_repository = resource_repository
        @data_object = data_object
        @validations = validations
        @logger = logger
      end

      def find_all(type:, account:)
        authenticator_webservices(type: type, account: account).map do |webservice|
          service_id = service_id_from_resource_id(webservice.id)
          begin
            load_authenticator(account: account, service_id: service_id, type: type)
          rescue => e
            @logger.info("failed to load #{type} authenticator '#{service_id}' do to validation failure: #{e.message}")
            nil
          end
        end.compact
      end

      def find(type:, account:,  service_id:)
        webservice_identifier = [type, service_id].compact.join('/')
        webservice = @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:webservice:conjur/#{webservice_identifier}"
          )
        ).first
        unless webservice
          raise Errors::Authentication::Security::WebserviceNotFound.new(webservice_identifier, account)
        end

        load_authenticator(account: account, service_id: service_id, type: type)
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

      def load_authenticator(type:, account:, service_id:)
        identifier = [type, service_id].compact.join('/')
        variables = @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:conjur/#{identifier}/%"
          )
        ).eager(:secrets).all
        args_list = {}.tap do |args|
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

        # Validate the variables against the authenticator contract
        result = @validations.call(args_list)
        if result.success?
          @data_object.new(**result.to_h)
        else
          errors = result.errors
          @logger.info(errors.to_h.inspect)

          # If contract fails, raise the first defined exception...
          error = errors.first
          raise(error.meta[:exception]) if error.meta[:exception].present?

          # Otherwise, it's a validation error so raise the appropriate exception
          raise(Errors::Conjur::RequiredSecretMissing,
                "#{account}:variable:conjur/#{type}/#{service_id}/#{error.path.first.to_s.dasherize}")
        end
      end
    end
  end
end
