module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Responsible for producing the SPIFFE ID format for a role
    class SpiffeId < Dry::Struct::Value
      attribute :issuer_id, Types::Strict::String
      attribute :requestor, CA::Requestor

      def to_s
        [
          'spiffe://conjur',
          requestor.account,
          issuer_id,
          requestor.kind,
          requestor.identifier
        ].join('/')
      end

    end
  end
end
