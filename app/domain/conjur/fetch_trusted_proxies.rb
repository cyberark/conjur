# frozen_string_literal: true

require 'command_class'

module Conjur

  FetchTrustedProxies ||= CommandClass.new(
    dependencies: {
      role_cls:                 ::Role,
      validate_account_exists:  ::Authentication::Security::ValidateAccountExists.new,
      logger:                   Rails.logger
    },
    inputs:       %i(account)
  ) do

    SETTINGS_POLICY_ID = "conjur/settings"
    TRUSTED_PROXIES_HOST_NAME = "trusted_proxies"

    def call
      validate_account_exists
      fetch_trusted_proxies_list
      delete_duplications_in_list
      trusted_proxies_list
    rescue => e
      raise Errors::Conjur::TrustedProxiesFetchFailed.new(
        e.inspect
      )
    end

    private

    def validate_account_exists
      @validate_account_exists.(
        account: @account
      )
    end

    def fetch_trusted_proxies_list
      @logger.debug(LogMessages::Conjur::FetchingTrustedProxies.new(host_id))
      @trusted_proxies_list = role.restricted_to || []
      @logger.debug(LogMessages::Conjur::FetchedTrustedProxies.new(@trusted_proxies_list.length))
    end

    def delete_duplications_in_list
      @logger.debug(LogMessages::Conjur::DeletingTrustedProxiesDuplications.new)
      if @trusted_proxies_list.any?
        @trusted_proxies_list = @trusted_proxies_list.uniq {|cidr| [cidr.to_s]}
      end
      @logger.debug(LogMessages::Conjur::TrustedProxiesAmount.new(@trusted_proxies_list.length))
    end

    def trusted_proxies_list
      @trusted_proxies_list
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
      @host_id ||= "host/#{SETTINGS_POLICY_ID}/#{TRUSTED_PROXIES_HOST_NAME}"
    end
  end
end

