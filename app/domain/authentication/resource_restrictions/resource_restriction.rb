module Authentication
  module ResourceRestrictions

    # This class instance holds the resource restriction extracted
    # from a host annotation.
    class ResourceRestriction
      attr_reader :name, :value

      def initialize(name:, value:)
        @name = name
        @value = value
      end
    end
  end
end
