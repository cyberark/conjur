# frozen_string_literal: true

require 'command_class'

module Conjur

  FetchTrustedProxies ||= CommandClass.new(
    dependencies: {
        role_cls:                 ::Role,
        validate_account_exists:  ::Authentication::Security::ValidateAccountExists.new,
        logger:                   Rails.logger
    },
    inputs: %i(account)
  ) do

    def call
      validate_account_exists
      fetch_trusted_proxies_list
      delete_duplications_in_list
      trusted_proxies_list
    rescue => e
      raise Errors::Conjur::TrustedProxiesMissing.new(
          host_id,
          e.inspect
      )
    end

    private

    def validate_account_exists
      @validate_account_exists.(
          account: @account
      )
    end

    def trusted_proxies_list
      @proxies_list
    end

    def delete_duplications_in_list
      @logger.debug(LogMessages::Conjur::DeletingTrustedProxiesDuplications.new)
      if @proxies_list
        @proxies_list = @proxies_list.uniq { |cidr| [cidr.to_s]}
      end
      @logger.debug(LogMessages::Conjur::TrustedProxiesAmount.new(@proxies_list.length))
    end

    def fetch_trusted_proxies_list
      @logger.debug(LogMessages::Conjur::FetchingTrustedProxies.new(host_id))
      @proxies_list = role.restricted_to
      unless @proxies_list
        @proxies_list = Array.new
      end
      @logger.debug(LogMessages::Conjur::FetchingTrustedProxies.new(@proxies_list.length))
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
