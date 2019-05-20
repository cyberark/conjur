# frozen_string_literal: true

module Authentication

  AuditEvent = CommandClass.new(
    dependencies: {
      role_cls: ::Role,
      audit_log: ::Authentication::AuditLog
    },
    inputs: %i(input success message)
  ) do

    def call
      @audit_log.record_authn_event(
        role: role,
        webservice_id: @input.webservice.resource_id,
        authenticator_name: @input.authenticator_name,
        success: @success,
        message: @message
      )
    end

    private

    def role
      return nil if username.nil?

      @role_cls.by_login(username, account: @input.account)
    end

    def username
      @input.username
    end
  end
end
