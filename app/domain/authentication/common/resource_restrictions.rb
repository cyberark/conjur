module Authentication
  module Common

    class ResourceRestrictions

      def initialize(resource_restrictions:)
        @resource_restrictions = resource_restrictions
      end

      def names
        @resource_restrictions.keys
      end

      def each(&block)
        @resource_restrictions.each(&block)
      end

    end

  end
end