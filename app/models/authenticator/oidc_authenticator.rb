module Authenticator
  class OidcAuthenticator < Authenticator
    attr_reader :name, :provider_uri, :client_id, :client_secret,
                :claim_mapping, :state, :nonce

    def initialize(account:, service_id:, required_payload_parameters:, name:,
                   provider_uri:, response_type:, client_id:, client_secret:,
                   claim_mapping:, state:, nonce:, redirect_uri:)
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