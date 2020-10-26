module Authentication
  module Constraints

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
