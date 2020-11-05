module Authentication
  module Constraints

    class ExclusiveConstraint

      def initialize(exclusive:)
        @exclusive = exclusive
      end

      def validate(resource_restrictions:)
        exclusive_restrictions = resource_restrictions & @exclusive
        if exclusive_restrictions.length > 1
          raise Errors::Authentication::Constraints::IllegalConstraintCombinations, exclusive_restrictions
        end
      end

    end
  end
end
