module Authentication
  module Constraints

    # This constraint is initialized with an array of strings.
    # They represent the list of resource restrictions that any one of them must be present.
    # Calling `validate` enforces this constraint on the given list of resource restrictions.
    class AnyConstraint

      def initialize(any:)
        @any = any
      end

      def validate(resource_restrictions:)
        restrictions_found = resource_restrictions & @any
        raise Errors::Authentication::Constraints::RoleMissingRequiredConstraints, @any if restrictions_found.empty?
      end
    end
  end
end
