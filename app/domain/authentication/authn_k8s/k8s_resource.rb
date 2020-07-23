module Authentication
  module AuthnK8s

    class K8sResource
      attr_reader :type, :value

      def initialize(type:, value:)
        @type = type
        @value = value
      end

      def ==(other_resource)
        @type == other_resource.type && @value == other_resource.value
      end
    end
  end
end
