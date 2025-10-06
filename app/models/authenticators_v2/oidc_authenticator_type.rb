# frozen_string_literal: true

module AuthenticatorsV2
  class OidcAuthenticatorType < AuthenticatorBaseType

    attr_reader(
      :provider_uri,
      :client_id,
      :client_secret,
      :claim_mapping,
      :account,
      :service_id,
      :redirect_uri,
      :response_type,
      :ca_cert,
      :name,
      :variables
    )

    def initialize(
      authenticator_dict
    )
      super(authenticator_dict)

      @provider_uri = variables[:provider_uri]
      @client_id = variables[:client_id]
      @client_secret = variables[:client_secret]
      @claim_mapping = variables[:claim_mapping]
      @name = variables[:name].present? ? variables[:name] : @service_id.titleize
      @response_type = variables[:response_type].present? ? variables[:response_type] : 'code'
      @provider_scope = variables[:provider_scope].present? ? variables[:provider_scope] : nil
      @redirect_uri = variables[:redirect_uri].present? ? variables[:redirect_uri] : nil
      @ca_cert = variables[:ca_cert].present? ? variables[:ca_cert] : nil

      # Set TTL to 60 minutes by default
      @token_ttl = variables[:token_ttl].present? ? variables[:token_ttl] : 'PT60M'
    end

    def data
      return {} if @variables.blank?

      fields = %i[
        ca_cert 
        token_ttl
        provider_uri
        id_token_user_property
        client_id
        provider_scope
        client_secret
        claim_mapping
        name
        response_type
        redirect_uri
      ]

      filter_variables(fields)
    end

    def scope
      (%w[openid email profile] + [*@provider_scope.to_s.split(' ')]).uniq.join(' ')
    end

    def type
      @type ||= self.class.to_s.split('::')[1].underscore.dasherize
    end

    def token_ttl
      return ActiveSupport::Duration.parse(@token_ttl.to_s).to_i if @token_ttl.to_s.present?

      # If token TTL has not been set on the authenticator, return nil so that it
      # can be set using the configured user/host TTL values downstream.
      nil
    rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
      raise Errors::Authentication::DataObjects::InvalidTokenTTL.new(resource_id, @token_ttl)
    end
  end
end
