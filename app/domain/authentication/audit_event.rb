# frozen_string_literal: true

module Authentication

  AuditEvent = CommandClass.new(
    dependencies: {
      role_cls:  ::Role,
      audit_log: ::Authentication::AuditLog
    },
    inputs:       %i(authenticator_input success message)
  ) do

    def call
      @audit_log.record_authn_event(
        role:               role,
        webservice_id:      @authenticator_input.webservice.resource_id,
        authenticator_name: @authenticator_input.authenticator_name,
        success:            @success,
        message:            @message
      )
    end

    private

    def role
      return nil if username.nil?

      @role_cls.by_login(username, account: @authenticator_input.account)
    end

    def username
      @authenticator_input.username
    end
  end
end
