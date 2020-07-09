require 'command_class'

module Conjur

  FetchPermittedProxies ||= CommandClass.new(
    dependencies: {
        validate_account_exists:             ::Authentication::Security::ValidateAccountExists.new,
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
          account: account
      )
    end

  end

  def permitted_proxies_list
    # TODO
  end

  def delete_duplications_in_list
    # TODO
  end

  def fetch_permitted_proxies_list
    # TODO: Return host: settings/trusted_proxies and extract restricted_to value
  end
end
