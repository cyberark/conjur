# frozen_string_literal: true

module Authentication

  LogAuditEvent = CommandClass.new(
    dependencies: {
      role_cls:  ::Role,
      resource_cls: ::Resource,
      audit_log: ::Audit.logger
    },
    inputs:       %i(authenticator_input event success message)
  ) do

    def call
      return unless role

      @event.new(
        role: role,
        authenticator_name: @authenticator_input.authenticator_name,
        service: @resource_cls[webservice_id],
        success: @success,
        error_message: @message
      ).log_to @audit_log
    end

    private

    def webservice_id
      @authenticator_input.webservice.resource_id
    end

    def role
      @authenticator_input.role
    end
  end
end
