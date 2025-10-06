# frozen_string_literal: true

module AuthenticatorsV2
  class JwtAuthenticatorType < AuthenticatorBaseType

    # Extracts and structures authentication parameters for JWT authenticator.
    #
    # @param [Hash] authenticator_params - Hash containing authentication parameters.
    # @return [Hash, nil] - Returns a structured hash of relevant parameters or `nil` if none exist.
    def data
      return {} if @variables.blank?

      identity = identity_fields
      {
        ca_cert: format_field(@variables[:ca_cert]),
        audience: format_field(@variables[:audience]),
        jwks_uri: format_field(@variables[:jwks_uri]),
        issuer: format_field(@variables[:issuer]),
        public_keys: parse_public_keys(@variables[:public_keys]),
        identity: identity.present? ? identity : nil
      }.compact
    end
      
    def identity_fields
      {
        token_app_property: format_field(@variables[:token_app_property]),
        identity_path: format_field(@variables[:identity_path]),
        enforced_claims: @variables[:enforced_claims].nil? ? nil : enforced_claims(@variables[:enforced_claims]),
        claim_aliases: @variables[:claim_aliases].nil? ? nil : claim_aliases(@variables[:claim_aliases])
      }.compact
    end
      
    def parse_public_keys(value)
      return nil unless value.present?

      JSON.parse(value, {
        symbolize_names: true,
        create_additions: false
      })
    end

    private

    # Processes `enforced_claims`, ensuring uniqueness and removing whitespace.
    #
    # @param [String] value - Comma-separated string of enforced claims.
    # @return [Array] - Returns a unique array of claim values.
    def enforced_claims(value)
      return [] if value.strip.empty?

      value.split(',', -1).map(&:strip).uniq
    end

    # Processes `claim_aliases` into a structured hash.
    #
    # @param [String] value - Comma-separated list of key-value pairs (e.g., `"role:admin,group:devs"`).
    # @return [Hash] - Parsed claim aliases as a hash `{ "role" => "admin", "group" => "devs" }`.
    def claim_aliases(value)
      return {} if value.strip.empty?

      value.split(',', -1).each_with_object({}) do |pair, aliases_hash|
        key_data = pair.split(':', 2)
        next if key_data.size != 2 || key_data[0].empty? || key_data[1].empty?

        annotation, claim = key_data

        aliases_hash[annotation.to_sym] = claim
      end
    end
  end
end
