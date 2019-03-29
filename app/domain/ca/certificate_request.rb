# frozen_string_literal: true

require 'dry-struct'

module CA
  # Represents a user or host's request for a signed certificate
  class CertificateRequest < Dry::Struct
    attribute :kind, Types::Strict::Symbol 
    attribute :role, Types.Definition(Role)
    attribute :params, Types::Strict::Hash
  end
end
