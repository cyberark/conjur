module Authentication
  module AuthnJwt
    module SigningKey
      # This class is a POJO class presents public-keys structure
      class PublicSigningKeys
        include ActiveModel::Validations
        include AttrRequired

        VALID_TYPES =  %w[jwks].freeze

        attr_required(:type, :value)

        validates(*required_attributes, presence: true)
        validates(:type, inclusion: { in: VALID_TYPES, message: "'%{value}' is not a valid public-keys type" })
        validate(:validate_value_is_jwks, if: -> { @type == "jwks" })

        def initialize(hash)
          raise Errors::Authentication::AuthnJwt::InvalidPublicKeys, "the value is not in valid JSON format" unless
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
          errors.add(:value, "is not a valid JWKS (RFC7517)") unless @value.is_a?(Hash) &&
            @value[:keys].is_a?(Array) &&
            !@value[:keys].empty?
        end
      end
    end
  end
end
