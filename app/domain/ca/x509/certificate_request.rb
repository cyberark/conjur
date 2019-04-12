# frozen_string_literal: true

require 'dry-struct'

module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Represents a user or host's request for a signed certificate
    class CertificateRequest < Dry::Struct
      class << self
        # :reek:LongParameterList
        # Creates a certificate request from Rails controller inputs
        def from_hash(
          role:,
          csr:,
          ttl: nil,
          **_other
        )
          verify_role_is_host(role)

          ttl = ttl.to_s.strip.empty? ? nil : ISO8601::Duration.new(ttl).to_seconds.to_i

          CertificateRequest.new(
            requested_by: role,
            csr: csr(csr),
            ttl: ttl
          )
        end

        private

        def csr(csr_data)
          raise ArgumentError, "Signing parameter 'csr' is missing." if csr_data.to_s.strip.empty?

          csr = ::Util::OpenSsl::X509::SmartCsr.new(csr_data)
          raise ::Exceptions::Forbidden, 'CSR cannot be verified' unless csr.verify(csr.public_key)
          
          csr
        end
        
        def verify_role_is_host(role)
          raise ArgumentError, "Requestor is not a host." unless role.kind == 'host'
        end
      end

      attribute :requested_by, Types.Definition(Role)
      attribute :csr, Types.Definition(Util::OpenSsl::X509::SmartCsr)
      attribute :ttl, Types::Strict::Nil | Types::Strict::Int.constrained(gt: 0)
    end
  end
end
