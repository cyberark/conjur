# frozen_string_literal: true

module Authentication

  LogAuditEvent = CommandClass.new(
    dependencies: {
      role_cls:  ::Role,
      resource_cls: ::Resource,
      audit_log: ::Audit.logger
    },
    inputs:       %i(authenticator_name webservice role client_ip event success message)
  ) do

    def call
      return unless @role

      @event.new(
        role: @role,
        client_ip: @client_ip,
        authenticator_name: @authenticator_name,
        service: @resource_cls[webservice_id],
        success: @success,
        error_message: @message
      ).log_to @audit_log
    end

    private

    def webservice_id
      @webservice.resource_id
    end
  end
end
