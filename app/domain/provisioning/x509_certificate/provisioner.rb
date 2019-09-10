# frozen_string_literal: true

require 'openssl'
require 'securerandom'

# The context provisioner provides secret values directly
# from the requests context (additional parameters provided
# alongside the policy document).
#
module Provisioning
  module X509Certificate
    class Provisioner
      def provision(input)
        # CSR may either come from context or another conjur variable
        # OR certificate may be self-signed
        now = Time.now
        issuer_cert = issuer_certificate(input.resource)

        OpenSSL::X509::Certificate.new.tap { |cert| 
          cert.subject = subject(input.resource)
          cert.issuer = (issuer_cert || cert).subject
          cert.not_before = now
          cert.not_after = now + ttl(input.resource)
          cert.public_key = public_key(input.resource)
          cert.serial = SecureRandom.random_number(2**160)
          cert.version = 2

          ef = OpenSSL::X509::ExtensionFactory.new
          ef.subject_certificate = cert
          ef.issuer_certificate = issuer_cert || cert

          p extensions(input.resource)

          extensions(input.resource).each do |args|
            cert.add_extension(ef.create_extension(*args))
          end

          cert.sign(issuer_private_key(input.resource), OpenSSL::Digest::SHA256.new)
        }.to_pem

      end

      private

      SUBJECT_NAME_FIELD_SPEC = [
        ['C',             OpenSSL::ASN1::PRINTABLESTRING],
        ['ST',            OpenSSL::ASN1::PRINTABLESTRING],
        ['L',             OpenSSL::ASN1::PRINTABLESTRING],
        ['O',             OpenSSL::ASN1::UTF8STRING],
        ['OU',            OpenSSL::ASN1::UTF8STRING],
        ['CN',            OpenSSL::ASN1::UTF8STRING],
        ['emailAddress',  OpenSSL::ASN1::UTF8STRING]
      ]
      def subject(resource)
        name_fields = SUBJECT_NAME_FIELD_SPEC.map { |spec|
          [spec[0], resource.annotation("provision/x509-certificate/subject/#{spec[0].downcase}"), spec[1]]
        }.reject { |spec| spec[1].nil? }
        OpenSSL::X509::Name.new(name_fields)  
      end

      def ttl(resource)
        ttl_value = resource.annotation('provision/x509-certificate/ttl')
        ISO8601::Duration.new(ttl_value).to_seconds 
      end
      
      def public_key(resource)
        private_key(resource).public_key
        
      end

      def private_key(resource)
        pkey_var = resource.annotation('provision/x509-certificate/private-key/variable')
        pkey_id = [resource.account, 'variable', pkey_var].join(":")
        # TODO: Requires permission check\
        pkey_data = Resource[pkey_id].last_secret.value
        pkey = OpenSSL::PKey::RSA.new pkey_data
      end

      def issuer_certificate(resource)
        # Check if this should be a self-signed certificate
        return nil if resource.annotation('provision/x509-certificate/issuer/certificate/self') == 'true'

        cert_var = resource.annotation('provision/x509-certificate/issuer/certificate/variable')
        cert_var_id = [resource.account, 'variable', cert_var].join(":")
        # TODO: Requires permission check
        cert_data = Resource[cert_var_id].last_secret.value
        OpenSSL::X509::Certificate.new cert_data
      end

      def issuer_private_key(resource)
        issuer_pkey_var = resource.annotation('provision/x509-certificate/issuer/private-key/variable')
        issuer_pkey_id = [resource.account, 'variable', issuer_pkey_var].join(":")
        # TODO: Requires permission check
        issuer_pkey_data = Resource[issuer_pkey_id].last_secret.value
        issuer_pkey = OpenSSL::PKey::RSA.new issuer_pkey_data
      end

      def extensions(resource)
        [
          ['subjectKeyIdentifier', 'hash'],
          ['authorityKeyIdentifier', 'keyid:always,issuer:always'],
          ['nsComment', 'Certificate created using CyberArk Conjur'],
          basic_constraints(resource),
          key_usage(resource),
          extended_key_usage(resource),
          subject_alt_names(resource)
        ].compact
      end

      def basic_constraints(resource)
        annotation_base = 'provision/x509-certificate/basic-constraints'
        critical = resource.annotation("#{annotation_base}/critical") == 'true'
        ca = resource.annotation("#{annotation_base}/ca") == 'true'
        path_len = (resource.annotation("#{annotation_base}/pathlen") || 0).to_i

        value = ca ? "CA:TRUE,pathlen:#{path_len}" : 'CA:FALSE'

        ['basicConstraints', value, critical]
      end

      KEY_USAGE_FIELD_SPEC = [
        ['key-cert-sign', 'keyCertSign'],
        ['crl-sign', 'cRLSign'],
        ['digital-signature', 'digitalSignature'],
        ['key-enchipherment', 'keyEncipherment']
      ]
      def key_usage(resource)
        annotation_base = 'provision/x509-certificate/key-usage'
        critical = resource.annotation("#{annotation_base}/critical") == 'true'

        value = KEY_USAGE_FIELD_SPEC.select { |spec|
          resource.annotation("#{annotation_base}/#{spec[0]}") == 'true'
        }.map { |spec| spec[1] }
        .join(',')

        ['keyUsage', value, critical] unless value == ''
      end

      EXT_KEY_USAGE_FIELD_SPEC = [
        ['client-auth', 'clientAuth'],
        ['server-auth', 'serverAuth']
      ]
      def extended_key_usage(resource)
        annotation_base = 'provision/x509-certificate/ext-key-usage'
        critical = resource.annotation("#{annotation_base}/critical") == 'true'

        value = EXT_KEY_USAGE_FIELD_SPEC.select { |spec|
          resource.annotation("#{annotation_base}/#{spec[0]}") == 'true'
        }.map { |spec| spec[1] }
        .join(',')

        ['extendedKeyUsage', value, critical] unless value == ''
      end

      def subject_alt_names(resource); end
    end
  end
end
