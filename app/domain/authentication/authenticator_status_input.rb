# frozen_string_literal: true

require 'types'

module Authentication
  class AuthenticatorStatusInput < ::Dry::Struct

    attribute :authenticator_name, ::Types::NonEmptyString
    attribute :service_id, ::Types::NonEmptyString.optional
    attribute :account, ::Types::NonEmptyString
    attribute :username, ::Types::NonEmptyString

    def webservice
      status_webservice.parent_webservice
    end

    def status_webservice
      @status_webservice ||= ::Authentication::StatusWebservice.from_webservice(
        ::Authentication::Webservice.new(
          account:            @account,
          authenticator_name: @authenticator_name,
          service_id:         @service_id
        )
      )
    end
  end
end
