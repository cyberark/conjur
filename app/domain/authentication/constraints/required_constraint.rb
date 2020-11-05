module Authentication
  module Constraints

    class RequiredConstraint

      def initialize(required:)
        @required = required
      end

      def validate(resource_restrictions:)
        missing_required_constraints = @required - resource_restrictions
        if missing_required_constraints.any?
          raise Errors::Authentication::Constraints::RoleMissingConstraints, missing_required_constraints
        end
      end

    end
  end
end
