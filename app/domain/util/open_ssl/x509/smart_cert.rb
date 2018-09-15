# A Certificate decorator that allows reading of the spiffe id and common name
#
require 'openssl'

module Util
  module OpenSsl
    module X509
      class SmartCert < SimpleDelegator

        class InvalidCert < RuntimeError
          def to_s
            'Cert must be a String or X509::Certificate'
          end
        end

        # Support both method of creation so that it will behave like an
        # `OpenSSL::X509::Certificate`
        #
        def initialize(cert)
          validate_cert(cert)
          cert = cert.is_a?(String) ? OpenSSL::X509::Certificate.new(cert) : cert
          super(cert)
        end

        def san
          san_ext&.value
        end

        # Removes the URI: prefix
        def san_uri
          san.sub(/^URI:/i, '')
        end

        def common_name
          smart_subject.common_name
        end

        def smart_subject
          @subject ||= SmartSubject.new(subject)
        end

        private

        def validate_cert(cert)
          valid = !cert.nil? && valid_type?(cert)
          raise InvalidCert unless valid
        end

        def valid_type?(cert)
          cert.is_a?(String) || cert.is_a?(OpenSSL::X509::Certificate)
        end

        # san = subject alt name
        #
        def san_ext
          extensions.find { |e| e.oid == "subjectAltName" }
        end

      end
    end
  end
end
