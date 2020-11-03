module Authentication
  module Constraints

    # This constraint aggregates multiple constraints and validates all of them.
    class MultipleConstraint

      def initialize(*args)
        @constraints = args
      end

      def validate(resource_restrictions:)
        @constraints.each do |constraint|
          constraint.validate(resource_restrictions: resource_restrictions)
        end
      end
    end
  end
end
