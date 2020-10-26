module Authentication
  module Constraints

    class RequiredConstraint

      def initialize(required:)
        @required = required
      end

      def validate(resource_restrictions:)
        (@required - resource_restrictions).each do |missing_required_constraint|
          raise Errors::Authentication::RoleMissingConstraint, missing_required_constraint
        end
      end

    end
  end
end
