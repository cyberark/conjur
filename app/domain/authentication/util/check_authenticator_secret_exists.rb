require 'command_class'
require 'conjur/fetch_required_secrets'

module Authentication
  module Util

    # Command class that returns boolean value indicating if resource exists
    CheckAuthenticatorSecretExists = CommandClass.new(
      dependencies: {
        resource_class: ::Resource,
        logger: Rails.logger
      },
      inputs: %i[conjur_account authenticator_name service_id var_name]
    ) do
      def call
        check_authenticator_secret_exists
      end

      private

      def check_authenticator_secret_exists
        @logger.debug(LogMessages::Util::CheckingResourceExists.new(resource_id))
        resource ? true : false
      end

      def resource
        @resource_class[resource_id]
      end

      def resource_id
        "#{@conjur_account}:variable:conjur/#{@authenticator_name}/#{@service_id}/#{@var_name}"
      end
    end
  end
end
