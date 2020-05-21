module Authentication
  module AuditEvent
    class Authenticate < ::Audit::Event::Authn   
      operation 'authenticate'
    
      success_message do
        "#{role_id} successfully authenticated with authenticator "\
          "#{authenticator_name}#{service_message_part}"
      end
    
      failure_message do
        "#{role_id} failed to authenticate with authenticator "\
          "#{authenticator_name}#{service_message_part}"
      end
    end
  end
end
