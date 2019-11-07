# frozen_string_literal: true

require 'openssl'

# Utility methods for CA tests
#
module CAHelpers

  def generate_root_ca
    RootCA.new('CN=Conjur Root CA/DC=Conjur Certificate Authority', 3600)
  end

  def generate_intermediate_ca(root_ca, password = nil)
    int_ca = IntermediateCA.new('CN=Conjur Intermediate CA/DC=Conjur Certificate Authority', password: password)
    int_ca.cert = root_ca.sign_ca(int_ca.csr, 3600)
    int_ca
  end

  def generate_ssh_ca(comment, password = nil)
    SshKey.new(comment, password: password)
  end

  def create_host(common_name)
    Host.new("CN=#{common_name}")
  end

  def create_ssh_key(comment)
    SshKey.new(comment)
  end

  def intermediate_ca
    @intermediate_ca ||= {}
  end

  def ssh_ca
    @ssh_ca ||= {}
  end

  def response_certificate
    @response_certificate ||= OpenSSL::X509::Certificate.new certificate_response_body
  end

  def response_ssh_certificate
    @response_ssh_certificate ||= Net::SSH::KeyFactory.load_data_public_key(certificate_response_body)
  end

  def certificate_response_body
    @certificate_response_body ||= (certificate_response_type == 'json' ? @result['certificate'] : @result)
  end

  def certificate_response_type
    @certificate_response_type ||= 'json'
  end
  
  # Provides certificate authority capabilities. This is
  # namely signing certificates for certificate signing requests (CSRs)
  module CertificateAuthority

    def sign_ca(csr, ttl)
      raise 'CSR cannot be verified' unless csr.verify csr.public_key

      csr_cert = OpenSSL::X509::Certificate.new
      csr_cert.serial = 0
      csr_cert.version = 3
      csr_cert.not_before = Time.now
      csr_cert.not_after = csr_cert.not_before + ttl
      csr_cert.subject = csr.subject
      csr_cert.public_key = csr.public_key
      csr_cert.issuer = @cert.subject

      extension_factory = OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = csr_cert
      extension_factory.issuer_certificate = @cert

      csr_cert.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash'))
      csr_cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:TRUE', true))
      csr_cert.add_extension(extension_factory.create_extension('keyUsage', 'cRLSign,keyCertSign', true))

      # Sign the issued CA certificate with the CA private key
      csr_cert.sign @key, OpenSSL::Digest::SHA256.new

      csr_cert
    end
  end

  # Provides certificate host capabilities. This includes
  # creating a certificate signing request (CSR) to submit
  # to an issuer CA
  module CertificateHost
    def key
      @key
    end

    def key_pem
      @password.to_s.empty? ? @key.to_pem : @key.to_pem(OpenSSL::Cipher::AES256.new(:CBC), @password)
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

  # Represent a root certificate authority. A root
  # CA creates and signs its own certificate
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
      cert.not_after = cert.not_before + ttl
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

  # Represents an Intermediate Certificate authority.
  # An Intermediate CA cannot sign its own certificate,
  # but must submit a CSR to an issuer CA.
  class IntermediateCA
    include CertificateAuthority
    include CertificateHost

    def initialize(name, password: nil, key_size: 4096)
      @name = OpenSSL::X509::Name.parse name
      @key = OpenSSL::PKey::RSA.new key_size
      @password = password
    end
  end

  # Represents a host to create a certificate signing request
  # for a host certificate
  class Host
    include CAHelpers::CertificateHost

    def initialize(name, key_size: 4096)
      @name = OpenSSL::X509::Name.parse name
      @key = OpenSSL::PKey::RSA.new key_size
    end
  end

  class SshKey
    def initialize(comments, key_size: 4096, password: nil)
      @comments = comments
      @key = OpenSSL::PKey::RSA.new key_size
      @password = password
    end

    def fingerprint
      @key.public_key.fingerprint
    end

    def private_key
      @password.to_s.empty? ? @key.to_pem : @key.to_pem(OpenSSL::Cipher::AES256.new(:CBC), @password)
    end

    def public_key
      @key.public_key.to_pem
    end
  end
end
World(CAHelpers)
