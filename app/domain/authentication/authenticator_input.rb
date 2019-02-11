# frozen_string_literal: true

module Authentication
  class Input

    attr_reader :authenticator_name, :service_id, :account, :request, :origin, :password
    attr_accessor :username

    def initialize(authenticator_name:, service_id:, account:, request:, origin:, username: nil, password: nil)
      @authenticator_name = authenticator_name
      @service_id = service_id
      @account = account
      @request = request
      @origin = origin
      @username = username
      @password = password
    end

    def initialize(attributes)
      attributes.each {|key, value| instance_variable_set("@#{key}", value)}
    end

    # Convert this Input to a Security::AccessRequest
    #
    def to_access_request(enabled_authenticators)
      ::Authentication::Security::AccessRequest.new(
        webservice: webservice,
        whitelisted_webservices: ::Authentication::Webservices.from_string(
          @account,
          enabled_authenticators ||
            Authentication::Common.default_authenticator_name
        ),
        user_id: @username
      )
    end

    def webservice
      @webservice ||= ::Authentication::Webservice.new(
        account: @account,
        authenticator_name: @authenticator_name,
        service_id: @service_id
      )
    end
  end
end
