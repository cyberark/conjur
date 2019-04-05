# frozen_string_literal: true

require 'net/ssh'

module Util
  module SSH
    module Certificate
      # :reek:LongParameterList
      # :reek:TooManyStatements
      def self.from_hash( # rubocop:disable Metrics/ParameterLists
        key_id:,
        type:, # :user or :host
        public_key:,
        principals:, 
        good_for:, # accepts any object with to_i
        serial: SecureRandom.random_number(2**160), # 20 bytes
        extensions: [],
        critical_options: []
      )
        now = Time.now

        cert = Net::SSH::Authentication::Certificate.new
        cert.key_id = key_id
        cert.key = public_key
        cert.valid_after = now
        cert.valid_before = now + good_for.to_i
        cert.valid_principals = principals
        cert.type = type
        cert.serial = serial

        cert.extensions = to_extensions_hash(extensions)
        cert.critical_options = to_extensions_hash(critical_options)

        cert
      end

      class << self
        private

        def to_extensions_hash(extensions)
          extensions.map { |args| [ args[0], args[1] || "" ]}.to_h
        end
      end
    end
  end
end
