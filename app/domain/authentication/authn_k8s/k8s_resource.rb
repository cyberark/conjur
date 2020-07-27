module Authentication
  module AuthnK8s

    class K8sResource
      attr_reader :type, :value

      def initialize(type:, value:)
        @type = type
        @value = value
      end

      def ==(other)
        @type == other.type && @value == other.value
      end
    end
  end
end
