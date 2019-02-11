# frozen_string_literal: true

require 'types'
require 'util/error_class'
require 'authentication/webservice'
require 'authentication/webservices'

module Authentication
  AuditEvent = CommandClass.new(
    dependencies: {
      role_cls: ::Role,
      audit_log: ::Authentication::AuditLog
    },
    inputs: %i(input success message)
  ) do

    def call
      audit(@input)
    end

    private

    def role(username, account)
      @role_cls.by_login(username, account: account)
    end

    def audit(input)
      @audit_log.record_authn_event(
        role: role(input.username, input.account),
        webservice_id: input.webservice.resource_id,
        authenticator_name: input.authenticator_name,
        success: @success,
        message: @message
      )
    end
  end
end
