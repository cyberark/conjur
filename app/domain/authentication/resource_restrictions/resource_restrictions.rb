module Authentication
  module ResourceRestrictions

    class ResourceRestrictions

      def initialize(resource_restrictions_hash:)
        @resource_restrictions_hash = resource_restrictions_hash
      end

      def names
        @resource_restrictions_hash.keys
      end

      def each(&block)
        @resource_restrictions_hash.each(&block)
      end

      def empty?
        @resource_restrictions_hash.empty?
      end

    end

  end
end
