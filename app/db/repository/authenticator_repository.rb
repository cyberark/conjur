module DB
  module Repository
    class AuthenticatorRepository
      def initialize(
        data_object:,
        resource_repository: ::Resource,
        logger: Rails.logger
      )
        @resource_repository = resource_repository
        @data_object = data_object
        @logger = logger
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
        return unless webservice

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
            next unless variable.secret

            args[variable.resource_id.split('/')[-1].underscore.to_sym] = variable.secret.value
          end
        end

        begin
          allowed_args = %i[account service_id] +
                        @data_object.const_get(:REQUIRED_VARIABLES) +
                        @data_object.const_get(:OPTIONAL_VARIABLES)
          args_list = args_list.select{ |key, value| allowed_args.include?(key) && value.present? }
          @data_object.new(**args_list)
        rescue ArgumentError => e
          @logger.debug("DB::Repository::AuthenticatorRepository.load_authenticator - exception: #{e}")
          nil
        end
      end
    end
  end
end
