# A declarative constructor for an X509::Certificate
#
# TODO: this could pulled out into a gem

require 'openssl'
require 'active_support/time'

module Util
  module OpenSsl
    module X509
      module Certificate

        # Create any cert, specify any of the options
        #
        def self.from_hash(
          subject:,
          issuer:,
          public_key:,
          good_for:, # accepts any object with to_i
          version: 2,
          serial: SecureRandom.random_number(2**160), # 20 bytes
          issuer_cert: nil, # if nil, assumed to be self
          extensions: [] # an array of arrays
        )
          now = Time.now

          cert = OpenSSL::X509::Certificate.new
          cert.subject = openssl_name(subject)
          cert.issuer = openssl_name(issuer)
          cert.not_before = now
          cert.not_after = now + good_for.to_i
          cert.public_key = public_key
          cert.serial = SecureRandom.random_number(2**160) # 20 bytes
          cert.version = 2

          ef = OpenSSL::X509::ExtensionFactory.new
          ef.subject_certificate = cert
          ef.issuer_certificate = issuer_cert || cert

          extensions.each do |args|
            cert.add_extension(ef.create_extension(*args))
          end

          cert
        end

        # Create basic cert with defaults quickly
        #
        def self.from_subject(subject:, key: nil, issuer: nil, alt_name: nil)
          key    ||= OpenSSL::PKey::RSA.new(2048)
          issuer ||= subject

          cert = from_hash(
            subject: subject,
            issuer: issuer,
            public_key: key.public_key,
            good_for: 10.years,
            extensions: [
              ['basicConstraints', 'CA:TRUE', true],
              %w[subjectKeyIdentifier hash],
              ['authorityKeyIdentifier', 'keyid:always,issuer:always']
            ] + alt_name_ext(alt_name)
          )
          cert.sign(key, OpenSSL::Digest.new('SHA256'))
          cert
        end

        # private_class_method or private inside a class << self block needed
        # to make class methods private
        #
        class << self
          private

          def alt_name_ext(alt_name)
            alt_name ? [['subjectAltName', alt_name]]: []
          end

          def openssl_name(name)
            is_obj = name.is_a?(OpenSSL::X509::Name)
            is_obj ? name : OpenSSL::X509::Name.parse(name)
          end
        end
      end
    end
  end
end
