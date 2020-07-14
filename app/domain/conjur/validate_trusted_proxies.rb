# frozen_string_literal: true

require 'command_class'

module Conjur

  ValidateTrustedProxies ||= CommandClass.new(
    dependencies: {
      fetch_trusted_proxies:  ::Conjur::FetchTrustedProxies,
      logger:                 Rails.logger
    },
    inputs:       %i(account proxies_list)
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
      #TODO: validation logic
    end
  end
end

