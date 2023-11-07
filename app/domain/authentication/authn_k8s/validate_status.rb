module Authentication
  module AuthnK8s
    # AuthnK8s::ValidateStatus raises an exception if the Kubernetes
    # authenticator is not configured properly or with inadequate permissions.
    ValidateStatus = CommandClass.new(
      dependencies: {},
      inputs: %i[account service_id]
    ) do
      def call
        # Kubernetes specific validations will be added here in follow up
        # stories. Creating a blank ValidateStatus allows the status endpoint
        # to function for Kubernetes authenticators and provide some shared
        # capabilities (e.g. is the authenticator enabled).
      end
    end
  end
end
