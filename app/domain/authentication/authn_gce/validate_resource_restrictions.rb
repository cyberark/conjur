module Authentication
  module AuthnGce

    # This class is responsible of validating resource restrictions which are configured on a Conjur host or user
    # against google JWT token.
    ValidateResourceRestrictions = CommandClass.new(
      dependencies: {
        extract_resource_restrictions:                ExtractResourceRestrictions.new,
        validate_resource_restrictions_configuration: ValidateResourceRestrictionsConfiguration.new,
        validate_resource_restrictions_match_jwt:     ValidateResourceRestrictionsMatchJWT.new,
        logger:                                       Rails.logger
      },
      inputs:       %i(account username credentials)
    ) do

      def call
        @logger.debug(LogMessages::Authentication::ValidatingResourceRestrictions.new)
        extract_resource_restrictions
        validate_resource_restrictions_configuration
        validate_resource_restrictions_match_jwt
        @logger.debug(LogMessages::Authentication::ValidatedResourceRestrictions.new)
      end

      private

      def extract_resource_restrictions
        resource_restrictions
      end

      def resource_restrictions
        @resource_restrictions ||= @extract_resource_restrictions.call(
          account:           @account,
          username:          @username,
          extraction_prefix: AUTHN_PREFIX
        )
      end

      def validate_resource_restrictions_configuration
        @validate_resource_restrictions_configuration.call(
          resource_restrictions: @resource_restrictions,
          permitted_constraints: prefixed_permitted_constraints
        )
      end

      def validate_resource_restrictions_match_jwt
        @validate_resource_restrictions_match_jwt.call(
          resource_restrictions: @resource_restrictions,
          decoded_token:         @credentials,
          restriction_prefix:    AUTHN_PREFIX
        )
      end

      def prefixed_permitted_constraints
        @prefixed_permitted_constraints ||= PERMITTED_CONSTRAINTS.map { |c| "#{AUTHN_PREFIX}#{c}" }
      end
    end
  end
end
