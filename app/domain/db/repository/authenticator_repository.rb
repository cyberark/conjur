# frozen_string_literal: true

module DB
  module Repository
    # This class is responsible for loading the variables associated with a
    # particular type of authenticator. Each authenticator requires a Data
    # Object and Data Object Contract (for validation). Data Objects that
    # fail validation are not returned.
    #
    # This class includes 4 public methods:
    #   - `find_all` - returns all available authenticators from an account
    #      with an optional filter by type
    #   - `find` - returns a single authenticator based on the provided type,
    #     account, and service identifier.
    #   - 'create' - given a authenticator model, create a new authenticator
    #      and then return that created authenticator
    #   - 'delete' - given a policy-id, delete the associated authenticator
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
        @success = Responses::Success
        @failure = Responses::Failure
      end

      # Querying for the authenticator webservice above includes the webservices
      # for the authenticator status. The filter below removes webservices that
      # don't match the authenticator policy.
      AUTHN_FILTER = %r{
        ^(conjur/authn-gcp # Capture GCP authenticators which don't include a service_id
        | # Negative lookahead (?!gcp) prevents picking up conjur/authn-gcp/status w/this rx
        conjur/authn-(?!gcp)[\w-]+/[\w-]+)$ 
      }x.freeze

      def find_all(account:, type: nil)
        authenticators = authenticators(type: type, account: account).map do |webservice|
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

      def count_all(account:, type: nil)
        webservices = authenticator_weservices(account: account, type: type, service_id: nil)
          .limit(nil).offset(nil)
          .all.select do |webservice|
            webservice.id.split(':', 3).last.match?(AUTHN_FILTER)
          end

        webservices.count
      end

      def find(type:, account:, service_id:)
        search_service_id = service_id
        # GCP has no service ID because there is only one GCP authenticator allowed per account
        search_service_id = nil if type == "authn-gcp"

        webservice = authenticators(type: type, account: account, service_id: search_service_id).first
        unless webservice
          resource_id = [type, service_id].compact.join('/')
          return @failure.new(
            "Authenticator: #{service_id} not found in account '#{account}'",
            status: :not_found,
            exception: Errors::Authentication::Security::WebserviceNotFound.new(resource_id)
          )
        end

        map_authenticator(
          identifier: id_array(webservice[:resource_id]),
          webservice: webservice,
          account: account
        )
      rescue => e
        @logger.info("#{type_error_message(type)} '#{service_id}' due to: #{e.message}")
        @failure.new(
          "Failed to retreive authenticator #{service_id} in account '#{account}'",
          exception: e,
          level: :debug
        )
      end

      # Takes an AuthenticatorBaseType model (or one of its children) and attempts to create
      # an object for it in the database
      def create(authenticator:)
        DB::Repository::Authenticator::Create.new(authenticator: authenticator).call.bind do |auth| 
          find(type: auth.type, account: auth.account, service_id: auth.service_id)
        end
      end

      def delete(policy_id:)
        policy = @resource_repository[resource_id: policy_id]

        delete_policy(policy)
      end

      private

      def delete_policy(root_resource)
        return unless root_resource

        visited = []
        stack = [root_resource]

        while stack.any?
          resource = stack.pop
          next if visited.include?(resource.resource_id)

          visited.unshift(resource.resource_id)
          # Enqueue owned resources
          owned_resources = ::Resource.where(owner_id: resource.resource_id)
          stack = (stack + owned_resources.to_a) unless owned_resources.empty?

          next if protected_resource?(resource)

          resource.destroy if ::Resource[resource_id: resource.resource_id]
          resource_role = ::Role[resource.resource_id]
          resource_role&.destroy

        end

        root_resource
      end

      # Determines if a resource can be deleted or not with this repository
      def protected_resource?(resource)
        _, type, name = resource.resource_id.split(":", 3)

        # Matches the authenticator base branch
        regexp = %r{^conjur/authn-\w+$}
        name.match?(regexp) && type == "policy"
      end

      def map_authenticator(identifier:,  webservice:, account:)
        annotations =  webservice[:annotations].is_a?(String) ? JSON.parse(webservice[:annotations]) : webservice[:annotations]

        @auth_type_factory.call({
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
        # For autn-gcp there is only one authenticator with no service ID so use a special search option
        return type if type == "authn-gcp"

        "#{type}/%"
      end

      def type_error_message(type)
        return  "failed to load authenticator"  unless type.present?

        "failed to load '#{type}' authenticator"
      end

      def id_array(id)
        full_id = id.split(':', 3).last
        full_id.split('/')
      end

      def resource_description(type:, account:, service_id:)
        base = "#{account}:webservice:conjur/"
        return "#{base}#{type}/#{service_id}" if service_id

        "#{base}#{resource_type_filter(type)}"
      end

      # authenticators takes a service_id, authn type and account 
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
      # Webservices are then filtered to remove any that end in status
      def authenticators(type:, account:, service_id: nil)
        authenticator_details(
          resources: authenticator_weservices(type: type, account: account, service_id: service_id)
        ).order(:resource_id).all.select do |webservice|
          webservice.id.split(':', 3).last.match?(AUTHN_FILTER)
        end
      end

      def authenticator_weservices(type:, account:, service_id:)
        @resource_repository.where(
          Sequel.like(
            Sequel.qualify(:resources, :resource_id),
            resource_description(type: type, account: account, service_id: service_id)
          )
        )
      end

      def authenticator_details(resources:)
        resources.left_join(:authenticator_configs, Sequel.qualify(:resources, :resource_id) => Sequel.qualify(:authenticator_configs, :resource_id))
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
          )
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
