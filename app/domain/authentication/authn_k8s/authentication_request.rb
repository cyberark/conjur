module Authentication
  module AuthnK8s

    # This class validates the k8s authentication request against the resource
    # restrictions configured in the policy for the requesting host.
    # It uses the 'validate_k8s_resource' command-class to validate a k8s
    # resource against the k8s API.
    # This command-class receives the resource's type and name as input.
    class AuthenticationRequest
      def initialize(namespace:, k8s_resource_validator:)
        @namespace = namespace
        @k8s_resource_validator = k8s_resource_validator
      end

      def valid_restriction?(restriction)
        case restriction.name
        when Restrictions::NAMESPACE
          if restriction.value != @namespace
            raise Errors::Authentication::AuthnK8s::NamespaceMismatch.new(@namespace, restriction.value)
          end
        when Restrictions::NAMESPACE_LABEL_SELECTOR
          @k8s_resource_validator.valid_namespace?(label_selector: restriction.value)
        else
          # Restrictions defined using '-', but the k8s client expects type with '_' instead.
          # e.g. 'restriction=stateful-set' converted to 'k8s_type=stateful_set'
          k8s_resource_type = restriction.name.tr('-', '_')
          @k8s_resource_validator.valid_resource?(type: k8s_resource_type, name: restriction.value)
        end

        # Validation is done internally, so it is always valid if reached this point.
        true
      end
    end
  end
end
