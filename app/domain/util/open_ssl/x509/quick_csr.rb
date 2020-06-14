# Currently this is useful mainly for tests, and allows you to quickly create CSRs with alt name extensions using a simple declarative interface
#
# TODO: Make this more robust and usable in more contexts, allow clients to set
# all of the possible basic info.  perhaps fork:
#
# https://github.com/fnando/csr
#
# The main feature we need here not available in that gem is altname extensions.

require 'openssl'
require_relative 'extension_request_attribute_value'

module Util
  module OpenSsl
    module X509
      class QuickCsr

        # Creates a basic CSR with with alt_names extensions.
        #
        # @param common_name [String] eg, 'example.com' 
        # @param rsa_key [OpenSSL::PKey::RSA]
        # @param alt_names [Array<String>] eg, ['URI:spiffe://cluster.local/foo']
        #
        def initialize(
          common_name:,
          rsa_key: OpenSSL::PKey::RSA.new(2048),
          alt_names: []
        )
          @cn = common_name
          @rsa_key = rsa_key
          @alt_names = alt_names
        end

        # @return [OpenSSL::X509::Request]
        #
        def request
          @request ||= signed_csr
        end

        private

        def signed_csr
          OpenSSL::X509::Request.new.tap do |csr|
            add_basic_info(csr)
            add_alt_name_attrs(csr)
            sign(csr)
          end
        end

        def add_basic_info(csr)
          csr.version = 0
          csr.subject = subject
          csr.public_key = @rsa_key.public_key
        end

        def add_alt_name_attrs(csr)
          return if @alt_names.empty?
          alt_name_attrs.reduce(csr) { |m, x| m.add_attribute(x); m }
        end

        def alt_name_attrs
          [
            OpenSSL::X509::Attribute.new('extReq', attribute_values),
            OpenSSL::X509::Attribute.new('msExtReq', attribute_values)
          ]
        end

        def sign(csr)
          csr.sign(@rsa_key, OpenSSL::Digest::SHA256.new)
        end

        def subject
          OpenSSL::X509::Name.new([ ['CN', @cn] ])
        end

        def attribute_values
          @attribute_values ||=
            ExtensionRequestAttributeValue.from_extensions(
              [alt_name_extension]
            ).value
        end

        def alt_name_extension
          OpenSSL::X509::ExtensionFactory.new.create_extension(
            'subjectAltName', @alt_names.join(',')
          )
        end
      end
    end
  end
end
