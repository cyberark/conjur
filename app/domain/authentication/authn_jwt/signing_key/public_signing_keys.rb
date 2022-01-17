module Authentication
  module AuthnJwt
    module SigningKey
      # This class is a POJO class presents public-keys structure
      class PublicSigningKeys
        include ActiveModel::Validations
        include AttrRequired

        VALID_TYPES =  %w[jwks].freeze
        INVALID_TYPE = "'%{value}' is not a valid public-keys type. Valid types are: #{VALID_TYPES.join(',')}".freeze
        INVALID_JSON_FORMAT = "Value not in valid JSON format".freeze
        INVALID_JWKS = "is not a valid JWKS (RFC7517)".freeze

        attr_required(:type, :value)

        validates(*required_attributes, presence: true)
        validates(:type, inclusion: { in: VALID_TYPES, message: INVALID_TYPE })
        validate(:validate_value_is_jwks, if: -> { @type == "jwks" })

        def initialize(hash)
          raise Errors::Authentication::AuthnJwt::InvalidPublicKeys, INVALID_JSON_FORMAT unless
            hash.is_a?(Hash)

          hash = hash.with_indifferent_access
          required_attributes.each do |key|
            send("#{key}=", hash[key])
          end
        end

        def validate!
          raise Errors::Authentication::AuthnJwt::InvalidPublicKeys, errors.full_messages.to_sentence unless valid?
        end

        private

        def validate_value_is_jwks
          errors.add(:value, INVALID_JWKS) unless @value.is_a?(Hash) &&
            @value[:keys].is_a?(Array) &&
            !@value[:keys].empty?
        end
      end
    end
  end
end
