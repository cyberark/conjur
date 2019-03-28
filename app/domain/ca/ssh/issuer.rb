module CA
  module SSH
    # IssuerPrivateKey represents the CA signing key stored in Conjur
    class Issuer < Dry::Struct
      attribute :service, Types.Definition(::CA::Webservice)

      def private_key
        @private_key ||= Util::OpenSsl::PrivateKey.from_hash(
          key: key_data,
          password: key_password
        )
      end

      private

      def key_data
        @key_data ||= service.variable_annotation('ca/private-key')
      end

      def key_password
        @key_password ||= service.variable_annotation('ca/private-key-password')
      end
    end
  end
end
