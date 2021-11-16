# frozen_string_literal: true

require 'command_class'

module Authentication

  LogAuditEvent ||= CommandClass.new(
    dependencies: {
      audit_logger: Audit.logger,
      audit_role_id_class: ::Audit::Event::Authn::RoleId
    },
    inputs: %i[authenticator_input audit_event_class error]
  ) do

    def call
      log_audit_event
    end

    private

    def log_audit_event
      @audit_logger.log(
        @audit_event_class.new(
          authenticator_name: @authenticator_input.authenticator_name,
          service: @authenticator_input.webservice,
          role_id: audit_role_id,
          client_ip: @authenticator_input.client_ip,
          success: successful_event?,
          error_message: @error
        )
      )
    end

    def audit_role_id
      @audit_role_id_class.new(
        role: @authenticator_input.role,
        account: @authenticator_input.account,
        username: @authenticator_input.username
      ).to_s
    end

    def successful_event?
      @error.nil?
    end
  end
end
