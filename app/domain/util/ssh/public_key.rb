# frozen_string_literal: true

require 'openssl'
require 'net/ssh'

module Util
  module SSH
    module PublicKey
      def self.from_pem(public_key)
        OpenSSL::PKey::RSA.new(public_key)
      end

      def self.from_openssh(public_key)
        Net::SSH::KeyFactory.load_data_public_key(public_key)
      end
    end
  end
end
