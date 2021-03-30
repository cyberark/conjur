# frozen_string_literal: true

module Authentication

  module Security

    ValidateAccountExists ||= CommandClass.new(
      dependencies: {
        role_class: ::Role
      },
      inputs: %i[account]
    ) do
      def call
        validate_account_exists
      end

      private

      def validate_account_exists
        raise Errors::Authentication::Security::AccountNotDefined, @account unless account_admin_role
      end

      def account_admin_role
        @role_class["#{@account}:user:admin"]
      end
    end
  end
end
