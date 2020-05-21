module Authentication
  module AuditEvent
    class Authenticate < ::Audit::Event::Authn   
      operation 'authenticate'
    
      success_message do
        format "%s successfully authenticated with authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end
    
      failure_message do
        format "%s failed to authenticate with authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end
    end
  end
end
