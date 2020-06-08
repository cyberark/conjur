# frozen_string_literal: true

module Authentication

  Err ||= Errors::Authentication
  # Possible Errors Raised:
  # InvalidOrigin, RoleNotFound

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
      return @role if @role

      @role = @role_cls.by_login(@username, account: @account)
      raise Err::Security::RoleNotFound, role_id unless @role
      @role
    end

    def role_id
      @role_id ||= @role_cls.roleid_from_username(@account, @username)
    end
  end
end
