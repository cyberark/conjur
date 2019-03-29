# frozen_string_literal: true

require 'dry-struct'

module CA
  # :reek:UncommunicativeModuleName
  module X509
    # Represents a user or host's request for a signed certificate
    class CertificateRequest < Dry::Struct::Value
      class << self
        # Creates a certificate request from Rails controller inputs
        def build(role:, params:)
          verify_role_is_host(role)

          ttl = params[:ttl].try { |value| ISO8601::Duration.new(value).to_seconds.to_i }

          CertificateRequest.new(
            requestor: CA::Requestor.from_role(role),
            csr: load_csr(params),
            ttl: ttl
          )
        end

        private

        def load_csr(params)
          csr_data = params[:csr]
          raise ArgumentError, "Signing parameter 'csr' is missing." unless csr_data.present?

          csr = ::Util::OpenSsl::X509::SmartCsr.new(csr_data)
          raise ::Exceptions::Forbidden, 'CSR cannot be verified' unless csr.verify(csr.public_key)
          
          csr
        end
        
        def verify_role_is_host(role)
          raise ArgumentError, "Requestor is not a host." unless role.kind == 'host'
        end
      end

      attribute :requestor, CA::Requestor
      attribute :csr, Types.Definition(Util::OpenSsl::X509::SmartCsr)
      attribute :ttl, Types::Strict::Nil | Types::Strict::Int.constrained(gt: 0)
    end
  end
end
