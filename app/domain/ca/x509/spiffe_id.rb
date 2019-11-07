module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Responsible for producing the SPIFFE ID format for a role
    class SpiffeId < Dry::Struct
      attribute :issuer_id, Types::Strict::String
      attribute :role, Types.Definition(Role)

      def to_s
        [
          'spiffe://conjur',
          role.account,
          issuer_id,
          role.kind,
          role.identifier
        ].join('/')
      end

    end
  end
end
