# A CSR decorator that allows reading of the spiffe id and common name.
#
require 'openssl'
require_relative 'extension_request_attribute_value'
require_relative 'smart_subject'

module Util
  module OpenSsl
    module X509
      class SmartCsr < SimpleDelegator

        # Support both method of creation so that it will behave like an
        # `OpenSSL::X509::Certificate`
        #
        def initialize(csr)
          csr = csr.is_a?(String) ?
            OpenSSL::X509::Request.new(csr) : csr
          super(csr)
        end

        # Assumes the spiffe_id is the first alt name
        #
        def spiffe_id
          return nil unless ext_req_attr
          @spiffe_id ||= subject_altname.sub(/^URI:/i, '')
        end

        def common_name
          smart_subject.common_name
        end

        def common_name=(common_name)
          smart_subject.common_name = common_name
        end

        # We don't just return subject as it might have been updated
        def subject_to_s
          smart_subject.to_s
        end

        private

        def smart_subject
          @subject ||= SmartSubject.new(subject)
        end

        def ext_req_attr_val
          ExtensionRequestAttributeValue.new(ext_req_attr.value)
        end

        def subject_altname
          ext_req_attr_val.extension('subjectAltName').value
        end

        def ext_req_attr
          attributes.find { |a| a.oid == 'extReq' }
        end

      end
    end
  end
end
