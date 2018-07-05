module Authentication
  class AuditLog
    def self.record_authn_event(role:, webservice_id:, authenticator_name:,
                                success:, message: nil)
      return unless role
      ::Audit::Event::Authn.new(
        role: role,
        authenticator_name: authenticator_name,
        service: Resource[webservice_id],
        success: success,
        error_message: message
      ).log_to Audit.logger
    end
  end
end
