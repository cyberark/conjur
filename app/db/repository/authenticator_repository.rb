module DB
  module Repository
    class AuthenticatorRepository
      def initialize(
        data_object:,
        resource_repository: ::Resource,
        logger: Rails.logger,
        pkce_support_enabled: Rails.configuration.feature_flags.enabled?(:pkce_support)
      )
        @resource_repository = resource_repository
        @data_object = data_object
        @logger = logger
        @pkce_support_enabled = pkce_support_enabled
      end

      def find_all(type:, account:)
        @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:webservice:conjur/#{type}/%"
          )
        ).all.map do |webservice|
          service_id = service_id_from_resource_id(webservice.id)

          # Querying for the authenticator webservice above includes the webservices
          # for the authenticator status. The filter below removes webservices that
          # don't match the authenticator policy.
          next unless webservice.id.split(':').last == "conjur/#{type}/#{service_id}"

          load_authenticator(account: account, service_id: service_id, type: type)
        end.compact
      end

      def find(type:, account:,  service_id:)
        webservice =  @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:webservice:conjur/#{type}/#{service_id}"
          )
        ).first
        unless webservice
          raise Errors::Authentication::Security::WebserviceNotFound, "#{type}/#{service_id}"
        end

        load_authenticator(account: account, service_id: service_id, type: type)
      end

      def exists?(type:, account:, service_id:)
        @resource_repository.with_pk("#{account}:webservice:conjur/#{type}/#{service_id}") != nil
      end

      private

      def service_id_from_resource_id(id)
        full_id = id.split(':').last
        full_id.split('/')[2]
      end

      def load_authenticator(type:, account:, service_id:)
        variables = @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:conjur/#{type}/#{service_id}/%"
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

        begin
          # Load the params into the authenticator contract
          contract = Authentication::AuthnJwt::V2::DataObjects::AuthenticatorContract.new
          result = contract.call(args_list)
          if result.success?
            @data_object.new(**args_list)
          else
            # If contract fails, raise the defined exception...
            errors = result.errors.to_h
            @logger.info(errors.inspect)

            _, key_errors = errors.first
            key_error = key_errors.first
            raise(key_error[:exception], key_error[:text])
          end

        rescue ArgumentError => e
          @logger.debug("DB::Repository::AuthenticatorRepository.load_authenticator - exception: #{e}")
          nil
        end
      end
    end
  end
end
