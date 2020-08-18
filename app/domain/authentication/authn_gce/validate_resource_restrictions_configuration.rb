module Authentication
  module AuthnGce

    # This class is responsible of validating resource restrictions configuration.
    # the allowed configuration is: Role should have at least 1 permitted constraints, and non of illegal constraints
    ValidateResourceRestrictionsConfiguration = CommandClass.new(
      dependencies: {
        logger: Rails.logger
      },
      inputs:       %i(resource_restrictions permitted_constraints)
    ) do

      def call
        @logger.debug(LogMessages::Authentication::AuthnGce::ValidatingResourceRestrictionsConfiguration.new)
        validate_restrictions_exist
        validate_constraints_are_permitted
        validate_restrictions_values_exist
        @logger.debug(LogMessages::Authentication::AuthnGce::ValidatedResourceRestrictionsConfiguration.new)
      end

      private

      def validate_restrictions_exist
        if @resource_restrictions.nil? || @resource_restrictions.empty?
          raise Errors::Authentication::AuthnGce::RoleMissingRequiredConstraints.new(@permitted_constraints)
        end
      end

      def validate_constraints_are_permitted
        @resource_restrictions.each do |r|
          resource_type = r.type
          unless @permitted_constraints.include?(resource_type)
            raise Errors::Authentication::ConstraintNotSupported.new(resource_type, @permitted_constraints)
          end 
        end
      end

      def validate_restrictions_values_exist
        @resource_restrictions.each do |r|
          resource_type = r.type
          resource_value = r.value
          if resource_value.nil? || resource_value.empty?
            raise Errors::Authentication::MissingResourceRestrictionsValue.new(resource_type)
          end
        end
      end
    end
  end
end
