require 'command_class'

module Authentication
  module Common

    ValidateResourceRestrictions = CommandClass.new(
        dependencies: {
            extract_resource_restrictions:  ExtractResourceRestrictions.new,
            logger:                         Rails.logger
        },
        inputs:   %i(authenticator_name service_id host_name account constraints authentication_request)
    ) do

      def call
        resource_restrictions = extract_resource_restrictions
        validate_resource_restrictions_configuration(resource_restrictions)
        validate_request_matches_resource_restrictions(resource_restrictions)
      end

      private

      def extract_resource_restrictions
        @extract_resource_restrictions.call(
            authenticator_name: @authenticator_name,
            service_id:         @service_id,
            host_name:          @host_name,
            account:            @account
        )
      end

      def validate_resource_restrictions_configuration(resource_restrictions)
        @constraints.validate(
            resource_restrictions: resource_restrictions.names
        )
      end

      def validate_request_matches_resource_restrictions(resource_restrictions)
        resource_restrictions.each do |restriction_name, restriction_value|
          if @authentication_request.retrieve_attribute(restriction_name) != restriction_value
            raise Errors::Authentication::Jwt::InvalidResourceRestrictions, restriction_name
          end
        end
      end

    end
  end
end
