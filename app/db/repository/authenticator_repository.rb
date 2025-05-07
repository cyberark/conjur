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
        authenticators = authenticator_webservices(type: type, account: account).map do |webservice|
          identifier = id_array(webservice[:resource_id])
          begin
            auth = map_authenticator(identifier: identifier, webservice: webservice, account: account)
            unless auth.success? 
              @logger.info(auth.message)
              next
            end
             
            auth.result
          rescue => e
            @logger.info("#{type_error_message(type)} '#{identifier[2]}' varibales due to: #{e.message}")
            nil
          end
        end.compact
        @success.new(authenticators)
      end

      def find(type:, account:, service_id:)
        webservice = authenticator_webservices(type: type, account: account, service_id: service_id).first
        unless webservice
          resource_id = [type, service_id].compact.join('/')
          return @failure.new(
            "Authenticator: #{service_id} not found in account '#{account}'",
            status: :not_found,
            exception: Errors::Authentication::Security::WebserviceNotFound.new(resource_id)
          )
        end
        
        begin
          map_authenticator(
            identifier: id_array(webservice[:resource_id]),
            webservice: webservice,
            account: account
          )
        rescue => e
          @failure.new(
            e.message,
            exception: e,
            level: :debug
          )
        end
      end

      # Takes an AuthenticatorBaseType model (or one of its children) and attempts to create
      # an object for it in the database
      def create(authenticator:)
        DB::Repository::Authenticator::CreateAuthenticator.new.call(authenticator: authenticator)
      end

      private

      def map_authenticator(identifier:,  webservice:, account:)
        annotations = JSON.parse(webservice[:annotations]) unless webservice[:annotations].nil?

        @auth_type_factory.create_authenticator_type({
          type: identifier[1],
          service_id: identifier[2],
          account: account,
          resource_id: webservice[:resource_id],
          enabled: webservice[:enabled],
          annotations: annotations,
          owner_id: webservice[:owner_id],
          variables: load_authenticator_variables(
            account: account,
            service_id: identifier[2],
            type: identifier[1]
          )
        })
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

      def resource_description(type:, account:, service_id:)
        base = "#{account}:webservice:conjur/"
        return "#{base}#{type}/#{service_id}" if service_id

        "#{base}#{resource_type_filter(type)}"
      end

      # authenticator_webservices takes a service_id, authn type and account 
      # to retrieve all the requested authenticators including their 
      # annotations and enabled status.
      # 
      # @param [model] service_id Set to nil by default to allow the query to search all authenticators
      # @param [symbol] type can be set to an authn-type like 'authn-oidc' or remain nil, and it will filter accordingly
      #   with service_id:     "cucmber:webservice:conjur/authn-oidc/okta"
      #   with type:           "cucmber:webservice:conjur/authn-oidc"
      #   with just account:   "cucmber:webservice:conjur/authn-"
      # @param [symbol] account is required
      # 
      # Webserrvices are then filtered to remove any that end in status
      def authenticator_webservices(type:, account:, service_id: nil)
        @resource_repository.where(
          Sequel.like(
            Sequel.qualify(:resources, :resource_id),
            resource_description(type: type, account: account, service_id: service_id)
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
        variables = Resource.where(
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
