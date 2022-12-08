# frozen_string_literal: true

module Authentication
  module Handler
    class StatusHandler
      def initialize(); end

      def call(status_input:, enabled_authenticators:)
        if status_input.authenticator_name == 'authn-oidc'
          namespace = Authentication::Util::NamespaceSelector.select(
            authenticator_type: status_input.authenticator_name
          )
          authenticator = DB::Repository::AuthenticatorRepository.new(
            data_object: "#{namespace}::DataObjects::Authenticator".constantize
          ).find(
            type: status_input.authenticator_name,
            account: status_input.account,
            service_id: status_input.service_id
          )
          return if authenticator.present?
        end

        Authentication::ValidateStatus.new.(
          authenticator_status_input: status_input,
          enabled_authenticators: enabled_authenticators
        )
      end
    end
  end
end
