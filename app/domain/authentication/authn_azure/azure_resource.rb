module Authentication
  module AuthnAzure

    class AzureResource
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
