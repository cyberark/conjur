# frozen_string_literal: true

require 'types'

module Authentication
  class AuthenticatorStatusInput < ::Dry::Struct
    include CurrentUser

    attribute :authenticator_name, ::Types::NonEmptyString
    attribute :service_id, ::Types::NonEmptyString.optional
    attribute :account, ::Types::NonEmptyString

    def status_webservice
      @status_webservice ||= ::Authentication::StatusWebservice.from_webservice(
        ::Authentication::Webservice.new(
          account:            @account,
          authenticator_name: @authenticator_name,
          service_id:         @service_id
        )
      )
    end

    def authenticator_webservice
      status_webservice.parent_webservice
    end

    def user
      current_user
    end
  end
end
