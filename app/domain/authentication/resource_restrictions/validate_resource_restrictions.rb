require 'command_class'

module Authentication
  module ResourceRestrictions

    # This command class validates the resource restrictions retrieved from the
    # @extract_resource_restrictions command class dependency.
    #
    # Its inputs are:
    # @authenticator_name - the name of the authenticator. e.g. authn-azure.
    # @service_id - the specific service ID requested to authenticate. So if
    #   the authenticator is `authn-azure/prod`, then `prod` is the service ID.
    # @role_name - the name of the requesting Conjur role as defined in the DB.
    #   Can be user name or host name.
    # @account - the Conjur account where the relevant entities are defined.
    # @constraints - an object that responds to validate(resource_restrictions)
    #   where resource_restrictions is an array of restrictions found for the
    #   requesting host. Usually will be `Constraints::MultipleConstraint`.
    # @authentication_request - an object that each authenticator needs to
    #   define. It should respond to retrieve_attribute(attribute_name) and
    #   return a value to use for comparison with the corresponsing value
    #   defined in the DB for the requesting host.
    ValidateResourceRestrictions = CommandClass.new(
      dependencies: {
        extract_resource_restrictions: ExtractResourceRestrictions.new,
        logger:                        Rails.logger
      },
      inputs:   %i(authenticator_name service_id role_name account constraints authentication_request)
    ) do

      def call
        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictions.new(@role_name))

        extract_resource_restrictions
        validate_resource_restrictions_configuration
        validate_request_matches_resource_restrictions

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictions.new)
      end

      private

      def extract_resource_restrictions
        resource_restrictions
      end

      def resource_restrictions
        @resource_restrictions ||= @extract_resource_restrictions.call(
          authenticator_name: @authenticator_name,
          service_id:         @service_id,
          role_name:          @role_name,
          account:            @account
        )
      end

      def validate_resource_restrictions_configuration
        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionsConfiguration.new)

        @constraints.validate(
          resource_restrictions: resource_restrictions.names
        )

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsConfiguration.new)
      end

      def validate_request_matches_resource_restrictions
        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionsValues.new)

        resource_restrictions.each do |restriction|
          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionOnRequest.new(restriction.name))

          next if @authentication_request.valid_restriction?(restriction)
          raise Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions, restriction.name
        end

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsValues.new)
      end
    end
  end
end
