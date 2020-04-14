# frozen_string_literal: true

module Authentication

  AuditLoginEvent = CommandClass.new(
    dependencies: {
      role_cls:  ::Role,
      audit_log: ::Authentication::AuditLog
    },
    inputs:       %i(authenticator_input success message)
  ) do

    def call
      @audit_log.record_login_event(
        role:               role,
        webservice_id:      @authenticator_input.webservice.resource_id,
        authenticator_name: @authenticator_input.authenticator_name,
        success:            @success,
        message:            @message
      )
    end

    private

    def role
      username ? @role_cls.by_login(username, account: @authenticator_input.account) :  nil
    end

    def username
      @authenticator_input.username
    end
  end
end
