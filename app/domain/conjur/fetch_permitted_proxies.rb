# frozen_string_literal: true

require 'command_class'

module Conjur

  FetchPermittedProxies ||= CommandClass.new(
    dependencies: {
        role_cls:                          ::Role,
        validate_account_exists:           ::Authentication::Security::ValidateAccountExists.new
    },
    inputs: %i(account)
  ) do

    def call
      validate_account_exists
      fetch_permitted_proxies_list
      delete_duplications_in_list
      permitted_proxies_list
    end

    private

    def validate_account_exists
      @validate_account_exists.(
          account: @account
      )
    end

    def permitted_proxies_list
      @proxies_list
    end

    def delete_duplications_in_list
      if @proxies_list
        @proxies_list = @proxies_list.uniq { |cidr| [cidr.to_s]}
      end
    end

    def fetch_permitted_proxies_list
      @proxies_list = role.restricted_to
    end

    def role
      return @role if @role

      @role = @role_cls.by_login(host_id, account: @account)
      raise Errors::Authentication::Security::RoleNotFound, role_id unless @role
      @role
    end

    def role_id
      @role_id ||= @role_cls.roleid_from_username(@account, host_id)
    end

    def host_id
      return "host/" + policy_id + "/" + host_name
    end

    def policy_id
      return "settings"
    end

    def host_name
      return "trusted_proxies"
    end
  end
end
