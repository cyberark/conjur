# frozen_string_literal: true

module Authentication
  AuditEvent = CommandClass.new(
    dependencies: {
      get_role_by_login: GetRoleByLogin.new,
      audit_log:         ::Authentication::AuditLog
    },
    inputs:       %i(input success message)
  ) do

    def call
      @audit_log.record_authn_event(
        role:               role(@input.username, @input.account),
        webservice_id:      @input.webservice.resource_id,
        authenticator_name: @input.authenticator_name,
        success:            @success,
        message:            @message
      )
    end

    private

    def role(username, account)
      return nil if username.nil?

      @get_role_by_login.(username: username, account: account)
    end
  end
end
