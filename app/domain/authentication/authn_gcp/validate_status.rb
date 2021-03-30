module Authentication
  module AuthnGcp

    ValidateStatus = CommandClass.new(
      dependencies: {
        discover_identity_provider: Authentication::OAuth::DiscoverIdentityProvider.new
      },
      inputs: %i[]
    ) do
      def call
        validate_provider_is_responsive
      end

      private

      def validate_provider_is_responsive
        @discover_identity_provider.(
          provider_uri: PROVIDER_URI
        )
      end
    end
  end
end
