module Authentication
  module AuthnGcp

    # This class is responsible of validating resource restrictions that configured on a Conjur host or user
    # against google JWT token.
    ValidateResourceRestrictions = CommandClass.new(
      dependencies: {
        extract_resource_restrictions:                ExtractResourceRestrictions.new,
        validate_resource_restrictions_configuration: ValidateResourceRestrictionsConfiguration.new,
        validate_resource_restrictions_match_jwt:     ValidateResourceRestrictionsMatchJWT.new,
        logger:                                       Rails.logger
      },
      inputs:       [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :account, :username, :credentials

      def call
        @logger.debug(LogMessages::Authentication::ValidatingResourceRestrictions.new)
        extract_resource_restrictions
        validate_resource_restrictions_configuration
        validate_resource_restrictions_match_jwt
        @logger.debug(LogMessages::Authentication::ValidatedResourceRestrictions.new)
      end

      private

      def extract_resource_restrictions
        @resource_restrictions ||= @extract_resource_restrictions.call(
          account:           account,
          username:          username,
          extraction_prefix: AUTHN_PREFIX
        )
      end

      def validate_resource_restrictions_configuration
        @validate_resource_restrictions_configuration.call(
          resource_restrictions: @resource_restrictions,
          permitted_constraints: PERMITTED_CONSTRAINTS
        )
      end

      def validate_resource_restrictions_match_jwt
        @validate_resource_restrictions_match_jwt.call(
          resource_restrictions: @resource_restrictions,
          decoded_token:         credentials,
          restriction_prefix:    AUTHN_PREFIX
        )
      end
    end
  end
end
