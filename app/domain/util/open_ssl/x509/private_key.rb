# frozen_string_literal: true

require 'openssl'

module Util
  module OpenSsl
    module PrivateKey
      def self.from_hash(
        key:,
        password: nil
      )
        if password.present?
          OpenSSL::PKey::RSA.new(key, password)
        else
          OpenSSL::PKey::RSA.new(key)
        end
      end
    end
  end
end
