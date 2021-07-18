module Authentication
  module Constraints

    # This constraint is initialized with an array of strings.
    # They represent resource restrictions that are not allowed
    # Calling `validate` enforces this constraint on the given list of resource restrictions.
    # If there is annotation for one of these non permitted values proper error would be thrown
    class NonPermittedConstraint

      def initialize(non_permitted:)
        @non_permitted = non_permitted
      end

      def validate(resource_restrictions:)
        any_non_permitted_restrictions = resource_restrictions & @non_permitted
        if any_non_permitted_restrictions.length > 0
          raise Errors::Authentication::Constraints::NonPermittedRestrictionGiven, any_non_permitted_restrictions
        end
      end
    end
  end
end
