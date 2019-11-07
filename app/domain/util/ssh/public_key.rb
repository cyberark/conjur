# frozen_string_literal: true

require 'openssl'
require 'net/ssh'

module Util
  module SSH
    class PublicKey < SimpleDelegator
      def initialize(raw_data, key_format = :openssh)
        super(parse_key(raw_data, key_format))
      end

      private

      def parse_key(raw_data, key_format)
        case key_format
        when :openssh
          Net::SSH::KeyFactory.load_data_public_key(raw_data)
        when :pem
          OpenSSL::PKey::RSA.new(raw_data)
        else
          raise ArgumentError, "Invalid public key format '#{key_format}'"
        end
      end
    end
  end
end
