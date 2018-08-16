# frozen_string_literal: true

require 'openssl'

# Utility methods for CA tests
#
module CAHelpers

  def generate_root_ca
    RootCA.new('CN=Conjur Root CA/DC=Conjur Certificate Authority', 3600)
  end

  def generate_intermediate_ca(root_ca)
    intermediate_ca = IntermediateCA.new('CN=Conjur Intermediate CA/DC=Conjur Certificate Authority')
    intermediate_ca.cert = root_ca.sign(intermediate_ca.csr, 3600, ca: true)
    intermediate_ca
  end

  def create_host(cn)
    Host.new("CN=#{cn}")
  end

  module CertificateAuthority

    def sign(csr, ttl, ca: false)
      raise 'CSR cannot be verified' unless csr.verify csr.public_key

      csr_cert = OpenSSL::X509::Certificate.new
      csr_cert.serial = 0
      csr_cert.version = 3
      csr_cert.not_before = Time.now
      csr_cert.not_after = Time.now + ttl

      csr_cert.subject = csr.subject
      csr_cert.public_key = csr.public_key
      csr_cert.issuer = @cert.subject

      extension_factory = OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = csr_cert
      extension_factory.issuer_certificate = @cert

      csr_cert.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash'))

      if ca
        csr_cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:TRUE', true))
        csr_cert.add_extension(extension_factory.create_extension('keyUsage', 'cRLSign,keyCertSign', true))
      else
        csr_cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:FALSE'))
        csr_cert.add_extension(extension_factory.create_extension('keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature', true))
      end

      csr_cert.sign @key, OpenSSL::Digest::SHA256.new

      csr_cert
    end
  end

  module CertificateHost
    def key
      @key
    end

    def cert
      @cert
    end

    def cert=(val)
      @cert = val
    end

    def csr
      OpenSSL::X509::Request.new
                            .tap do |csr|
                              csr.version = 0
                              csr.subject = @name
                              csr.public_key = @key.public_key
                              csr.sign @key, OpenSSL::Digest::SHA256.new
                            end
    end
  end

  class RootCA
    include CertificateAuthority
    include CertificateHost

    def initialize(name, ttl, key_size: 4096)
      @name = OpenSSL::X509::Name.parse name
      @key = OpenSSL::PKey::RSA.new key_size
      @cert = create_cert(ttl, @key)
    end

    def create_cert(ttl, key)
      cert = OpenSSL::X509::Certificate.new

      cert.version = 3
      cert.serial = 0
      cert.not_before = Time.now
      cert.not_after = Time.now + ttl
      cert.public_key = key.public_key
      cert.subject = @name
      cert.issuer = @name

      extension_factory = OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = cert
      extension_factory.issuer_certificate = cert

      cert.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash'))
      cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:TRUE', true))
      cert.add_extension(extension_factory.create_extension('keyUsage', 'cRLSign,keyCertSign', true))

      cert.sign(key, OpenSSL::Digest::SHA256.new)

      cert
    end
  end

  class IntermediateCA
    include CertificateAuthority
    include CertificateHost

    def initialize(name, key_size: 4096)
      @name = OpenSSL::X509::Name.parse name
      @key = OpenSSL::PKey::RSA.new key_size
    end
  end

  class Host
    include CAHelpers::CertificateHost

    def initialize(name, key_size: 4096)
      @name = OpenSSL::X509::Name.parse name
      @key = OpenSSL::PKey::RSA.new key_size
    end
  end
end
World(CAHelpers)
