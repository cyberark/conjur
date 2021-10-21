# Provides schema validation for authenticator specific Conjur Resources

module Authentication
  module AuthnK8s
    class Validations

      def validate_host(annotations:, errors:)
        %w[namespace service-account].each do |attr|
          unless annotations.keys.include?(attr)
            errors << "The annotation authn-k8s/#{attr} is required for an authn-k8s host"
          end
        end
      end

    end
  end
end
