module Authentication
  module AuthnGCP

    # This class is responsible of validating resource restrictions combination.
    # the allowed combination is: Role should have at least 1 permitted constraints, and non of illegal constraints
    class RestrictionsValidator

      ILLEGAL_STATE_MISSING_CONSTRAINTS_MESSAGE = "constraints are missing or empty"
      ILLEGAL_STATE_MISSING_RESOURCE_TYPE_MESSAGE = "resource restriction type is missing or empty"
      ILLEGAL_STATE_DUPLICATE_CONSTRAINTS_MESSAGE = "constraints contain duplications"
      ILLEGAL_STATE_DUPLICATE_RESTRICTIONS_MESSAGE = "resource restrictions contain duplications"

      def initialize(resource_restrictions:, permitted_constraints:, logger:)
        @resource_restrictions = resource_restrictions
        @permitted_constraints = permitted_constraints
        @logger = logger

        @logger.debug(LogMessages::Authentication::AuthnGCP::ValidatingRestrictionsConstraintCombination.new)
        validate
        @logger.debug(LogMessages::Authentication::AuthnGCP::ValidatedRestrictionsConstraintCombination.new)
      end

      private

      def validate
        input_validation
        validate_constraints_are_permitted
        validate_restrictions_values_exist
      end

      def input_validation
        validate_constraints_exist
        validate_restrictions_exist
        validate_restrictions_types_exist
        validate_there_are_no_duplicated_constraints
        validate_there_are_no_duplicated_restrictions
      end

      def validate_constraints_exist
        if @permitted_constraints.nil? || @permitted_constraints.empty?
          raise Errors::Authentication::IllegalStateResourceRestrictionsValidation.new(ILLEGAL_STATE_MISSING_CONSTRAINTS_MESSAGE)
        end
      end

      def validate_restrictions_types_exist
        @resource_restrictions.each do |r|
          resource_type = r.type
          if resource_type.nil? || resource_type.empty?
            raise Errors::Authentication::IllegalStateResourceRestrictionsValidation.new(ILLEGAL_STATE_MISSING_RESOURCE_TYPE_MESSAGE)
          end
        end
      end

      def validate_there_are_no_duplicated_constraints
        if @permitted_constraints.uniq!
          raise Errors::Authentication::IllegalStateResourceRestrictionsValidation.new(ILLEGAL_STATE_DUPLICATE_CONSTRAINTS_MESSAGE)
        end
      end

      def validate_there_are_no_duplicated_restrictions
        if !@resource_restrictions.nil? && resource_restrictions_types.uniq!
          raise Errors::Authentication::IllegalStateResourceRestrictionsValidation.new(ILLEGAL_STATE_DUPLICATE_RESTRICTIONS_MESSAGE)
        end
      end

      def validate_restrictions_exist
        if @resource_restrictions.nil? || @resource_restrictions.empty?
          raise Errors::Authentication::RoleMissingRequiredConstraints.new(@permitted_constraints)
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

      def resource_restrictions_types
        return @resource_restrictions_types if @resource_restrictions_types

        @resource_restrictions_types = Array.new
        @resource_restrictions.each do |r|
          resource_type = r.type
          next unless resource_type
          @resource_restrictions_types.push(resource_type)
        end

        @resource_restrictions_types
      end
    end
  end
end
