module DB
  module Repository
    class AuthenticatorRepository
      def initialize(
        data_object:,
        resource_repository: ::Resource,
        logger: Rails.logger,
        enabled_authenticators: Rails.application.config.conjur_config.authenticators
      )
        @resource_repository = resource_repository
        @data_object = data_object
        @logger = logger
        @enabled_authenticators = enabled_authenticators
      end

      def find_all(type:, account:)
        enabled_authenticator_types = @enabled_authenticators.select { |authenticator| authenticator.match("#{type}") }
                .map { |authenticator| "#{account}:webservice:conjur/#{authenticator}" }
       @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:webservice:conjur/#{type}/%"
          )
        ).all.select { |webservice|enabled_authenticator_types.include?(webservice.resource_id) }.map do |webservice|
          load_authenticator(account: account, id: webservice.id.split(':').last, type: type)
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

        load_authenticator(account: account, id: webservice.id.split(':').last, type: type)
      end

      def exists?(type:, account:, service_id:)
        @resource_repository.with_pk("#{account}:webservice:conjur/#{type}/#{service_id}") != nil
      end

      private

      def load_authenticator(type:, account:, id:)
        service_id = id.split('/')[2]
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
          @data_object.new(**args_list)
        rescue ArgumentError => e
          @logger.debug("DB::Repository::AuthenticatorRepository.load_authenticator - exception: #{e}")
          nil
        end
      end
    end
  end
end
