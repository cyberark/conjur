# frozen_string_literal: true

require 'openssl'

# The context provisioner provides secret values directly
# from the requests context (additional parameters provided
# alongside the policy document).
#
module Provisioning
  module X509CSR

    class Provisioner
      def provision(input)
        # Read private key from Conjur variable

        # TODO: Need to check permissions before doing this, we are doing this
        # on behalf of the policy loader
        pkey_var = input.resource.annotation('provision/x509-csr/private-key-variable')
        pkey_id = [ input.resource.account, 'variable', pkey_var ].join(":")
        pkey_data = Resource[pkey_id].last_secret.value
        pkey = OpenSSL::PKey::RSA.new pkey_data

        OpenSSL::X509::Request.new.tap { |request|
          request.version = 0 
          request.subject = subject_name_from_annotations(input.resource)
          request.public_key = pkey.public_key
          request.sign(pkey, OpenSSL::Digest::SHA1.new)
        }.to_pem
      end

      private 

      SUBJECT_NAME_FIELD_SPEC = [
        ['C',  OpenSSL::ASN1::PRINTABLESTRING],
        ['ST', OpenSSL::ASN1::PRINTABLESTRING],
        ['L',  OpenSSL::ASN1::PRINTABLESTRING],
        ['O',  OpenSSL::ASN1::UTF8STRING],
        ['OU',  OpenSSL::ASN1::UTF8STRING],
        ['CN', OpenSSL::ASN1::UTF8STRING],
        ['emailAddress',  OpenSSL::ASN1::UTF8STRING]
      ]

      def subject_name_from_annotations(resource)
        name_fields = SUBJECT_NAME_FIELD_SPEC.map { |spec|
            spec.insert(1, resource.annotation("provision/x509-csr/subject/#{spec[0].downcase}"))
        }.reject { |spec| spec[1].nil? }
        OpenSSL::X509::Name.new(name_fields)  
      end
    end
  end
end
