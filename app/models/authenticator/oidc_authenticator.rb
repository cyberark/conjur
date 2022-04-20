module Authenticator
  class OidcAuthenticator < Authenticator
    attr_reader :name, :provider_uri, :response_type, :client_id,
                :client_secret, :claim_mapping, :state, :nonce, :redirect_uri

    def initialize(account:, service_id:, required_payload_parameters: nil,
                   name: nil, provider_uri: nil, response_type: nil,
                   client_id: nil, client_secret: nil, claim_mapping: nil,
                   state: nil, nonce: nil, redirect_uri: nil)
      super(
        account: account,
        service_id: service_id,
        required_payload_parameters: required_payload_parameters
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
    end

    def is_valid?
      return super.is_valid? && @name && @provider_uri && @response_type &&
        @client_id && @client_secret && @claim_mapping && @state && @nonce &&
        @redirect_uri
    end
  end
end