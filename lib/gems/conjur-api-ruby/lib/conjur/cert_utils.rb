#
# Copyright 2013-2017 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

module Conjur
  module CertUtils
    CERT_RE = /-----BEGIN CERTIFICATE-----\n.*?\n-----END CERTIFICATE-----\n/m

    class << self
      # Parse X509 DER-encoded certificates from a string
      # @param certs [String] certificate(s) to parse in DER form
      # @return [Array<OpenSSL::X509::Certificate>] certificates contained in the string
      def parse_certs certs
        # fix any mangled namespace
        certs = certs.gsub /\s+/, "\n"
        certs.gsub! "-----BEGIN\nCERTIFICATE-----", '-----BEGIN CERTIFICATE-----'
        certs.gsub! "-----END\nCERTIFICATE-----", '-----END CERTIFICATE-----'
        certs += "\n" unless certs[-1] == "\n"

        certs.scan(CERT_RE).map do |cert|
          begin
            OpenSSL::X509::Certificate.new cert
          rescue OpenSSL::X509::CertificateError => exn
            raise exn, "Invalid certificate:\n#{cert} (#{exn.message})"
          end
        end
      end
    end
  end
end
