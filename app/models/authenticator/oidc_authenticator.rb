module Authenticator
  class OidcAuthenticator < Authenticator::Authenticator
    AUTH_VERSION_1 = 'V1'
    AUTH_VERSION_2 = 'V2'
    attr_reader :name, :provider_uri, :response_type, :client_id,
                :client_secret, :claim_mapping, :state, :nonce, :redirect_uri,
                :version, :scope

    def initialize(account:, service_id:, required_request_parameters: nil,
                   name: nil, provider_uri: nil, response_type: nil,
                   client_id: nil, client_secret: nil, claim_mapping: nil,
                   state: nil, nonce: nil, redirect_uri: nil, id_token_user_property: nil,
                   scope: nil)
      super(
        account: account,
        service_id: service_id,
        required_request_parameters: required_request_parameters
      )

      @name = name
      @provider_uri = provider_uri
      @response_type = response_type
      @client_id = client_id
      @client_secret = client_secret
      @claim_mapping = claim_mapping
      @state = state
      @nonce = nonce
      @redirect_uri = redirect_uri
      @scope = scope

      if id_token_user_property
        # this is the older version of the Oidc authenticator - conform
        @required_request_parameters = [:credentials]
        @claim_mapping = id_token_user_property
        @version = AUTH_VERSION_1 if @provider_uri
      end

      if @name && @provider_uri && @response_type && @client_id && @client_secret && @claim_mapping && @state && @nonce && @redirect_uri && @scope
        @version = AUTH_VERSION_2
      end
    end

    def is_valid?
      return super && (@version == AUTH_VERSION_1 || @version == AUTH_VERSION_2)
    end

    def authenticator_name
      return "authn-oidc/#{self.service_id}"
    end

    def resource_id
      return "#{account}:webservice:conjur/authn-oidc/#{self.service_id}"
    end
  end
end