module Authentication
  module AuthnOidc
    class TokenIdentity
      attr_reader :subscription_id, :resource_group
      attr_accessor :system_assigned_identity, :user_assigned_identity

      def initialize(subscription_id:, resource_group:)
        @subscription_id = subscription_id
        @resource_group = resource_group
      end
    end
  end
end
