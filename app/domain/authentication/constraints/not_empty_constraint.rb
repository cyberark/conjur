module Authentication
  module Constraints

    # This constraint returns true if the resource restriction contains at least one restriction. Otherwise it raises
    # EmptyAnnotationsListConfigured exception
    class NotEmptyConstraint
      def validate(resource_restrictions:)
        raise Errors::Authentication::Constraints::RoleMissingAnyRestrictions if resource_restrictions.empty?
      end
    end
  end
end
