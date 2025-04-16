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
        auth_type_factory: AuthenticatorsV2::AuthenticatorTypeFactory.new,
        resource_repository: ::Resource,
        logger: Rails.logger
      )
        @resource_repository = resource_repository
        @auth_type_factory = auth_type_factory
        @logger = logger
        @success = ::SuccessResponse
        @failure = ::FailureResponse
      end

      def find_all(account:, type: nil)
        authenticators = authenticator_webservices(resources: @resource_repository, type: type, account: account).map do |webservice|
          identifier = id_array(webservice[:resource_id])
          begin
            auth = map_authenticator(identifier: identifier, webservice: webservice, account: account)
            return auth unless auth.success?

            auth.result
          rescue => e
            @logger.info("#{type_error_message(type)} '#{identifier[2]}' due to validation failure: #{e.message}")
            nil
          end
        end.compact
        @success.new(authenticators)
      end

      def find_all_if_visible(type:, account:, role:, options: {})
        resources =  @resource_repository.visible_to(role).search(**options)
        authenticators = authenticator_webservices(resources: resources, type: type, account: account).map do |webservice|
          identifier = id_array(webservice[:resource_id])
          begin
            auth = map_authenticator(identifier: identifier, webservice: webservice, account: account)
            return auth unless auth.success?

            auth.result
          rescue => e
            @logger.info("#{type_error_message(type)} '#{identifier[2]}' due to validation failure: #{e.message}")
            nil
          end
        end.compact

        @success.new(authenticators)
      end

      def find(type:, account:, service_id:)
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
          auth = load_authenticator_variables(
            account: account,
            service_id: service_id,
            type: type
          )
          auth[:service_id] = service_id
          auth[:account] = account

          @success.new(auth)
        rescue => e
          @failure.new(
            e.message,
            exception: e,
            level: :debug
          )
        end
      end

      private

      def map_authenticator(identifier:,  webservice:, account:)
        res = {
          type: identifier[1],
          service_id: identifier[2],
          account: account,
          resource_id: webservice[:resource_id],
          enabled: webservice[:enabled],
          annotations: webservice[:annotations],
          owner_id: webservice[:owner_id]
        }
        res[:variables] = load_authenticator_variables(account: account, service_id: identifier[2], type: identifier[1])
        
        @auth_type_factory.create_authenticator_type(res)
      end

      def resource_type_filter(type)
        return "authn-%" unless type
  
        "#{type}/%"
      end

      def type_error_message(type)
        return  "failed to load authenticator"  unless type.present?
  
        "failed to load '#{type}' authenticator" 
      end
  
      def id_array(id)
        full_id = id.split(':').last
        full_id.split('/')
      end

      # authenticator_webservices takes a resouce repo, authn type and account 
      # to retrieve all the requested authenticators including their 
      # annotations and enabled status.
      # 
      # @param [model] resouces can be pre-filtered by roles or search option as seen in find_all_if_visible()
      # @param [symbol] type can be set to an authn-type like 'authn-oidc' or remain nil, and it will filter accordingly
      #   with type: "cucmber:webservice:conjur/authn-oidc"
      #   without: "cucmber:webservice:conjur/authn-"
      # @param [symbol] account is required
      # 
      # Webserrvices are then filtered to remove any that end in status
      def authenticator_webservices(resources:, type:, account:)
        resources.where(
          Sequel.like(
            Sequel.qualify(:resources, :resource_id),
            "#{account}:webservice:conjur/#{resource_type_filter(type)}"
          )
        )
          .left_join(:authenticator_configs, Sequel.qualify(:resources, :resource_id) => Sequel.qualify(:authenticator_configs, :resource_id))
          .left_join(:annotations, Sequel.qualify(:resources, :resource_id) => Sequel.qualify(:annotations, :resource_id))
          .select(
            Sequel.qualify(:resources, :resource_id),
            Sequel.qualify(:resources, :owner_id),
            Sequel.function(:COALESCE, Sequel.qualify(:authenticator_configs, :enabled), false).as(:enabled),
            Sequel.function(
              :COALESCE,
              Sequel.function(
                :jsonb_object_agg,
                Sequel.qualify(:annotations, :name),
                Sequel.qualify(:annotations, :value)
              ).filter(Sequel.lit('annotations.name IS NOT NULL'))
            ).as(:annotations)
          ).group(
            Sequel.qualify(:resources, :resource_id),
            Sequel.qualify(:resources, :owner_id),
            Sequel.qualify(:authenticator_configs, :enabled)
          ).order(:resource_id).all.select do |webservice|
            # Querying for the authenticator webservice above includes the webservices
            # for the authenticator status. The filter below removes webservices that
            # don't match the authenticator policy.
            webservice.id.split(':').last.match?(%r{^conjur/authn-[\w-]+/[\w-]+$})
          end
      end

      def load_authenticator_variables(type:, account:, service_id:)
        identifier = [type, service_id].compact.join('/')
        variables = @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:conjur/#{identifier}/%"
          )
        ).all
        {}.tap do |args|
          variables.each do |variable|
            # If variable exists but does not have a secret, set the value to an empty string.
            # This is used downstream for validating if a variable has been set or not, and thus,
            # what error to raise.
            value = variable.secret ? variable.secret.value : ''
            args[variable.identifier.split('/', 4)[-1].underscore.to_sym] = value
          end
        end  
      end
    end
  end
end
