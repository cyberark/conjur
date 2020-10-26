module Authentication
  module Constraints

    class PermittedConstraint

      def initialize(permitted:)
        @permitted = permitted
      end

      def validate(resource_restrictions:)
        (resource_restrictions - @permitted).each do |not_supported_restriction_name|
          raise Errors::Authentication::ConstraintNotSupported.new(
              not_supported_restriction_name,
              @permitted
          )
        end
      end

    end
  end
end
