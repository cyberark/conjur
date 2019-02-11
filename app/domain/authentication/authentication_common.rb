# frozen_string_literal: true

module Authentication
  class Common

    def self.validate_security(input, env)
      ::Authentication::ValidateSecurity.new.(
        input_to_validate: input,
          env: env
      )
    end

    def self.validate_origin(input)
      ::Authentication::ValidateOrigin.new.(
        input_to_validate: input
      )
    end

    def self.audit_success(input)
      ::Authentication::AuditEvent.new.(
        input: input,
          success: true,
          message: nil
      )
    end

    def self.audit_failure(input, err)
      ::Authentication::AuditEvent.new.(
        input: input,
          success: false,
          message: err.message
      )
    end
  end
end
