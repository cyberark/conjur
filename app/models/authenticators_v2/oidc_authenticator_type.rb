# frozen_string_literal: true

require_relative './authenticator_base_type'

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

    def add_data_params(variables)
      return {} if variables.blank?

      fields = %i[
        provider_uri
        client_id
        provider_scope
        client_secret
        claim_mapping
        name
        response_type
        redirect_uri
        ca_cert
        token_ttl
      ]

      fields.each_with_object({}) do |key, data_field|
        data_field[key] = retrieve_authenticator_variable(variables, key)
      end.compact
    end

    def scope
      (%w[openid email profile] + [*@provider_scope.to_s.split(' ')]).uniq.join(' ')
    end

    def type
      @type ||= self.class.to_s.split('::')[1].underscore.dasherize
    end

    def identifier
      [@type, @service_id].compact.join('/')
    end

    def provider_details
      details = @variables
      details[:service_id] = @service_id
      details[:account] = @account

      details
    end

    def resource_id
      [
        @account,
        'webservice',
        [
          'conjur',
          @type,
          @service_id
        ].compact.join('/')
      ].join(':')
    end

    def variable_prefix
      "#{@account}:variable:conjur/#{identifier}"
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
