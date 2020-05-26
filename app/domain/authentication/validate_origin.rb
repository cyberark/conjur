# frozen_string_literal: true

module Authentication

  Err ||= Errors::Authentication
  # Possible Errors Raised:
  # InvalidOrigin

  ValidateOrigin ||= CommandClass.new(
    dependencies: {
      role_cls: ::Role,
      logger:   Rails.logger
    },
    inputs: %i(account username origin)
  ) do

    def call
      raise Err::InvalidOrigin unless role.valid_origin?(@origin)
      @logger.debug(LogMessages::Authentication::OriginValidated.new.to_s)
    end

    private

    def role
      @role_cls.by_login(@username, account: @account)
    end
  end
end
