module Authentication
  module AuditEvent
    class Login < ::Audit::Event::Authn  
      operation 'login'

      success_message do
        "#{role_id} successfully logged in with authenticator "\
          "#{authenticator_name}#{service_message_part}"
      end

      failure_message do
        "#{role_id} failed to login with authenticator "\
          "#{authenticator_name}#{service_message_part}"
      end
    end
  end
end
