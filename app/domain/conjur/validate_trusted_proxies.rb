# frozen_string_literal: true

require 'command_class'

module Conjur

  ValidateTrustedProxies ||= CommandClass.new(
    dependencies: {
      fetch_trusted_proxies:  ::Conjur::FetchTrustedProxies.new,
      logger:                 Rails.logger
    },
    inputs:       %i(account proxy_list)
  ) do

    def call
      fetch_trusted_proxies_list
      validate_proxies
    end

    private

    def fetch_trusted_proxies_list
      @trusted_proxies_list ||= @fetch_trusted_proxies.(
        account: @account
      )
    end

    def validate_proxies
      return if @trusted_proxies_list.blank? || @proxy_list.blank?

      @logger.debug(LogMessages::Conjur::ValidatingProxyList.new(@proxy_list.map {|ip| ip.to_s}))
      @proxy_list.each do |ip_addr|
        valid_proxy?(ip_addr)
      end
      @logger.debug(LogMessages::Conjur::ProxyListValidated.new)
    end

    def valid_proxy?(ip_addr)
      @trusted_proxies_list.each do |cidr|
        return if cidr.include?(ip_addr)
      end
      raise Errors::Conjur::InvalidProxy, ip_addr.to_s
    end
  end
end

