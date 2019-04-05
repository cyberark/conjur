# frozen_string_literal: true

require 'dry-struct'

module CA
  # :reek:UncommunicativeModuleName
  module SSH
    # Represents a user or host's request for a signed certificate
    class CertificateRequest < Dry::Struct
      class << self
        # Creates a certificate request from Rails controller inputs
        def build(role:, params:)
          CertificateRequest.new(
            requestor: CA::Requestor.from_role(role),
            public_key: load_public_key(params),
            principals: load_principals(params),
            ttl: load_ttl(params)
          )
        end

        private

        def load_public_key(params)
          public_key_data = params[:public_key]
          raise ArgumentError, "Request is missing public key for signing" unless public_key_data.present?

          key_format = (params[:public_key_format].presence || 'openssh').downcase.to_sym
          Util::SSH::PublicKey.new(public_key_data, key_format)
        end
  
        def load_principals(params)
          principals = params[:principals]
          raise ArgumentError, "Signing parameter 'principals' is missing." unless principals.present?

          Array(principals)
        end

        def load_ttl(params)
          params[:ttl].try { |value| ISO8601::Duration.new(value).to_seconds.to_i }
        end
      end

      attribute :requestor, CA::Requestor
      attribute :public_key, Types.Definition(Util::SSH::PublicKey)
      attribute :principals, Types::Strict::Array.of(Types::Coercible::String)
      attribute :ttl, Types::Strict::Nil | Types::Strict::Int.constrained(gt: 0)
    end
  end
end
