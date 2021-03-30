require 'openssl'

module Conjur
  module CertUtils
    CERT_RE ||= /-----BEGIN CERTIFICATE-----\n.*?\n-----END CERTIFICATE-----\n/m

    class << self
      # Parse X509 DER-encoded certificates from a string
      # @param certs [String] certificate(s) to parse in DER form
      # @return [Array<OpenSSL::X509::Certificate>] certificates contained in the string
      def parse_certs certs
        # fix any mangled namespace
        certs = certs.gsub(/\s+/, "\n")
        certs.gsub!("-----BEGIN\nCERTIFICATE-----", '-----BEGIN CERTIFICATE-----')
        certs.gsub!("-----END\nCERTIFICATE-----", '-----END CERTIFICATE-----')
        certs += "\n" unless certs[-1] == "\n"

        certs.scan(CERT_RE).map do |cert|
          
          OpenSSL::X509::Certificate.new(cert)
        rescue OpenSSL::X509::CertificateError => e
          raise e, "Invalid certificate:\n#{cert} (#{e.message})"
          
        end
      end

      # Add a certificate to a given store. If the certificate has more than
      # one certificate in its chain, it will be parsed and added to the store
      # one by one. This is done because `OpenSSL::X509::Store.new.add_cert`
      # adds only the intermediate certificate to the store.
      def add_chained_cert store, chained_cert
        parse_certs(chained_cert).each do |cert|
          
          store.add_cert(cert)
        rescue OpenSSL::X509::StoreError => e
          raise unless e.message == 'cert already in hash table'
          
        end
      end
    end
  end
end
