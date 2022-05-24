module Authentication
  module Constraints

    class RequiredExclusiveConstraint

      def initialize(required_exclusive:)
        @required_exclusive = required_exclusive
      end

      def validate(resource_restrictions:)
        restrictions_found = resource_restrictions & @required_exclusive
        raise Errors::Authentication::Constraints::IllegalExclusiveRequiredCombination, @required_exclusive unless restrictions_found.length == 1
      end

    end
  end
end
