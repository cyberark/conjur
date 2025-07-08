# frozen_string_literal: true

require_relative './authenticator_base_type'

module AuthenticatorsV2
  class JwtAuthenticatorType < AuthenticatorBaseType

    # Extracts and structures authentication parameters for JWT authenticator.
    #
    # @param [Hash] authenticator_params - Hash containing authentication parameters.
    # @return [Hash, nil] - Returns a structured hash of relevant parameters or `nil` if none exist.
    def add_data_params(authenticator_params)
      return {} if authenticator_params.nil? || authenticator_params.empty?

      standard_fields = %i[ca_cert audience jwks_uri public_keys issuer]
      identity_fields = %i[token_app_property identity_path enforced_claims claim_aliases]

      processors = {
        enforced_claims: method(:process_enforced_claims),
        claim_aliases: method(:process_claim_aliases)
      }

      data_section = standard_fields.each_with_object({}) do |key, data|
        if key == :public_keys
          data[key] = parse_public_keys(authenticator_params[key])
          next
        end

        data[key] = retrieve_authenticator_variable(authenticator_params, key)
      end.compact

      identity_source = authenticator_params[:identity] || authenticator_params

      identity_section = identity_fields.each_with_object({}) do |key, identity|
        processor = processors.fetch(key, nil)

        value = retrieve_authenticator_variable(identity_source, key)
        value = processor.call(value) unless processor.nil? || value.nil?

        identity[key] = value
      end.compact  # Remove nil values

      data_section[:identity] = identity_section unless identity_section.empty?

      data_section
    end

    def parse_public_keys(value)
      return nil unless value.present?
      
      JSON.parse(
        value,
        {
          symbolize_names: true,
          create_additions: false
        }
      )
    end

    private

    # Processes `enforced_claims`, ensuring uniqueness and removing whitespace.
    #
    # @param [String] value - Comma-separated string of enforced claims.
    # @return [Array] - Returns a unique array of claim values.
    def process_enforced_claims(value)
      return [] if value.strip.empty?

      value.split(',', -1).map(&:strip).uniq
    end

    # Processes `claim_aliases` into a structured hash.
    #
    # @param [String] value - Comma-separated list of key-value pairs (e.g., `"role:admin,group:devs"`).
    # @return [Hash] - Parsed claim aliases as a hash `{ "role" => "admin", "group" => "devs" }`.
    def process_claim_aliases(value)
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
