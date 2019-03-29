# frozen_string_literal: true

require 'dry-struct'

module CA
  # Represents a certificate formatted to plain text
  class FormattedCertificate < Dry::Struct::Value
    attribute :content, Types::Strict::String 
    attribute :content_type, Types::Strict::String

    def to_s
      content
    end
  end
end
