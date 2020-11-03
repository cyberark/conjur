module Authentication
  module Constraints

    # This constraint is initialized with an array of strings.
    # They represent the only resource restrictions that may be present.
    # Calling `validate` enforces this constraint on the given list of resource restrictions.
    class PermittedConstraint

      def initialize(permitted:)
        @permitted = permitted
      end

      def validate(resource_restrictions:)
        not_supported_restrictions = resource_restrictions - @permitted
        if not_supported_restrictions.any?
          raise Errors::Authentication::Constraints::ConstraintNotSupported.new(
            not_supported_restrictions,
            @permitted
          )
        end
      end
    end
  end
end
