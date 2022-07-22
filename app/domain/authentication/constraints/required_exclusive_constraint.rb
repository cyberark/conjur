module Authentication
  module Constraints

    # This constraint is initialized with an array of strings.
    # They represent resource restrictions where exactly one is required.
    class RequiredExclusiveConstraint

      def initialize(required_exclusive:)
        @required_exclusive = required_exclusive
      end

      def validate(resource_restrictions:)
        restrictions_found = resource_restrictions & @required_exclusive
        raise Errors::Authentication::Constraints::IllegalRequiredExclusiveCombination.new(@required_exclusive, restrictions_found) unless restrictions_found.length == 1
      end

    end
  end
end
