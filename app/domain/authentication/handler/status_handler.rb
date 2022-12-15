# frozen_string_literal: true

module Authentication
  module Handler
    class StatusHandler
      def initialize(
        namespace_selector: Authentication::Util::NamespaceSelector,
        original_status_validator: Authentication::ValidateStatus.new,
        original_installed_authenticators: Authentication::InstalledAuthenticators
      )
        @namespace_selector = namespace_selector
        @original_status_validator = original_status_validator
        @original_installed_authenticators = original_installed_authenticators
      end

      def call(status_input:, enabled_authenticators:)
        if status_input.authenticator_name == 'authn-oidc'
          namespace = @namespace_selector.select(
            authenticator_type: status_input.authenticator_name
          )
          begin
            status = "#{namespace}::Status".constantize.new(
              available_authenticators: enabled_authenticators
            )
            status.call(
              account: status_input.account,
              authenticator_type: status_input.authenticator_name,
              service_id: status_input.service_id
            )

            # If a relevant Status is not found, fallback to original status check
          rescue NameError
            run_original_status_validation(status_input: status_input)
          end

        # If we know the old style is used, run the original status check
        else
          run_original_status_validation(status_input: status_input)
        end
      end

      def run_original_status_validation(status_input:)
        @original_status_validator.(
          authenticator_status_input: status_input,
          enabled_authenticators: @original_installed_authenticators.enabled_authenticators_str
        )
      end
    end
  end
end
