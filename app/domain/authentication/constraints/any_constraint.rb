module Authentication
  module Constraints

    class AnyConstraint

      def initialize(any_of:)
        @any = any_of
      end

      def validate(resource_restrictions:)
        restrictions_found = resource_restrictions & @any
        if restrictions_found.empty?
          raise Errors::Authentication::AuthnGcp::RoleMissingRequiredConstraints, @any
        end
      end

    end
  end
end
