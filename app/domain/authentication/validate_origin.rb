# frozen_string_literal: true

module Authentication

  ValidateOrigin ||= CommandClass.new(
    dependencies: {
      role_cls: ::Role,
      logger:   Rails.logger
    },
    inputs: %i(account username client_ip)
  ) do

    def call
      raise Errors::Authentication::InvalidOrigin unless role.valid_origin?(@client_ip)
      @logger.debug(LogMessages::Authentication::OriginValidated.new.to_s)
    end

    private

    def role
      return @role if @role

      @role = @role_cls.by_login(@username, account: @account)
      raise Errors::Authentication::Security::RoleNotFound, role_id unless @role
      @role
    end

    def role_id
      @role_id ||= @role_cls.roleid_from_username(@account, @username)
    end
  end
end
