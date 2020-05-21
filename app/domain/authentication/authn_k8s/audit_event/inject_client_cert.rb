module Authentication
  module AuthnK8s
    module AuditEvent
      class InjectClientCert < ::Audit::Event::Authn
        operation 'k8s-inject-client-cert'

        success_message do
          "#{role_id} successfully injected client certificate with authenticator "\
            "#{authenticator_name}#{service_message_part}"
        end

        failure_message do
          "#{role_id} failed to inject client certificate with authenticator "\
            "#{authenticator_name}#{service_message_part}"
        end
      end
    end
  end
end
