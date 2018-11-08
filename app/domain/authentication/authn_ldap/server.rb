# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'net/ldap'

module Authentication
  module AuthnLdap

    class Server
      def self.new(config)
        Net::LDAP.new(config.settings)
      end
    end
  end
end
