module Authentication
  module ResourceRestrictions

    class ResourceRestrictions

      def initialize(resource_restrictions_hash:)
        @resource_restrictions_hash = {}
        resource_restrictions_hash.each do |name, value|
          @resource_restrictions_hash[name] = ResourceRestriction.new(name: name, value: value)
        end
      end

      def names
        @resource_restrictions_hash.keys
      end

      def each(&block)
        @resource_restrictions_hash.each_value(&block)
      end

      def any?
        @resource_restrictions_hash.any?
      end

      # Returns a new ResourceRestrictions object without the given restriction.
      # Original object left untouched to keep it immutable.
      def except(resource_restriction_name)
        remainder = self.class.new(resource_restrictions_hash: {})
        remainder.resource_restrictions_hash = @resource_restrictions_hash.except(resource_restriction_name)
        remainder
      end

      protected

      attr_writer :resource_restrictions_hash
    end
  end
end
