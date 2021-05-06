require 'command_class'

module Authentication
  module AuthnJwt
    ValidateResourceRestrictions = CommandClass.new(
      dependencies: {
        logger: Rails.logger,
        extract_resource_restrictions: Authentication::ResourceRestrictions::ExtractResourceRestrictions.new,
        # TODO: Dependency for validate_resource_restrictions_configuration should be added here
        # TODO: Dependency for validate_request_matches_resource_restrictions should be added here
      },
      inputs: %i[authentication_parameters]
    ) do
      def call
        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictions.new(@authentication_parameters.jwt_identity))

        extract_resource_restrictions_configuration
        validate_resource_restrictions_configuration
        validate_token_matches_resource_restrictions

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictions.new)
      end

      private

      def extract_resource_restrictions_configuration
        @resource_restrictions ||= @extract_resource_restrictions.call(
          authenticator_name: @authentication_parameters.authenticator_name,
          service_id: @authentication_parameters.service_id,
          role_name: @authentication_parameters.jwt_identity,
          account: @authentication_parameters.account
        )
      end

      def validate_resource_restrictions_configuration
        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionsConfiguration.new)
        # TODO: Code of Validate Source Restriction Should be inserted here
        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsConfiguration.new)
      end

      def validate_token_matches_resource_restrictions
        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionsValues.new)

        # TODO: Code responsible of validating jwt token and the restrictions should be inserted here

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsValues.new)
      end
    end
  end
end
