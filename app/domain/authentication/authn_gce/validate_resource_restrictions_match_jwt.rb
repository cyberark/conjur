module Authentication
  module AuthnGce

    # This class is responsible of validating resource restrictions values against JWT token.
    # the assumption is that resource restrictions list contains only permitted types which already validated
    # in previous steps
    ValidateResourceRestrictionsMatchJWT = CommandClass.new(
      dependencies: {
        logger: Rails.logger
      },
      inputs:       %i(resource_restrictions decoded_token restriction_prefix)
    ) do

      def call
        @logger.debug(LogMessages::Authentication::AuthnGce::ValidatingResourceRestrictionsValues.new)
        validate
        @logger.debug(LogMessages::Authentication::AuthnGce::ValidatedResourceRestrictionsValues.new)
      end

      private

      def validate
        @resource_restrictions.each do |r|
          restriction_type = r.type
          restriction_value = r.value
          restriction_value_from_token = restriction_value_from_token(restriction_type_without_prefix(restriction_type))
          unless restriction_value == restriction_value_from_token
            raise Errors::Authentication::Jwt::InvalidResourceRestrictions.new(restriction_type)
          end
          @logger.debug(LogMessages::Authentication::ValidatedResourceRestrictionValue.new(restriction_type))
        end
      end

      def restriction_type_without_prefix(restriction_type)
        restriction_type.sub(@restriction_prefix, "")
      end

      def restriction_value_from_token(restriction_type)
        case restriction_type
        when PROJECT_ID_RESTRICTION_NAME
          restriction_value_from_token = @decoded_token.project_id
        when INSTANCE_NAME_RESTRICTION_NAME
          restriction_value_from_token = @decoded_token.instance_name
        when SERVICE_ACCOUNT_ID_RESTRICTION_NAME
          restriction_value_from_token = @decoded_token.service_account_id
        when SERVICE_ACCOUNT_EMAIL_RESTRICTION_NAME
          restriction_value_from_token = @decoded_token.service_account_email
        end

        restriction_value_from_token
      end
    end
  end
end
