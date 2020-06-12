module Authentication
  module AuditEvent
    class ValidateStatus < ::Audit::Event::Authn  
      operation 'validate-status'

      success_message do
        "#{role_id} successfully validated status for authenticator "\
          "#{authenticator_name}#{service_message_part}"
      end

      failure_message do
        "#{role_id} failed to validate status for authenticator "\
          "#{authenticator_name}#{service_message_part}"
      end
    end
  end
end
