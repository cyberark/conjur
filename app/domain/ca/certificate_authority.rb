# frozen_string_literal: true

require 'securerandom'

module CA
  # CertificateAuthority implements the signing capabilities
  # for a Conjur configure CA service
  class CertificateAuthority

    attr_reader :service

    # Creates a Certificate Authority from a configured Conjur webservice
    # 
    # Params:
    # - service: Conjure `Resource` representing the configured CA
    #               webservice.
    def initialize(service)
      @service = service
    end

    # Signs a certificate signing request (CSR) returning the X.509
    # certificate
    #
    # csr: OpenSSL::X509::Request. Certificate signing request to sign
    # ttl: Integer. The desired lifetime, in seconds, for the 
    #               certificate 
    def sign_csr(role, csr, ttl)
      csr_cert = OpenSSL::X509::Certificate.new

      # Generate a random 20 byte (160 bit) serial number for the certificate
      csr_cert.serial = SecureRandom.random_number(1<<160)

      # This value is zero-based. This is a version 3 certificate.
      csr_cert.version = 2

      now = Time.now
      csr_cert.not_before = now
      csr_cert.not_after = now + [ttl, max_ttl].min 
      csr_cert.subject = subject(role)
      csr_cert.public_key = csr.public_key
      csr_cert.issuer = certificate.subject
  
      extension_factory = OpenSSL::X509::ExtensionFactory.new
      extension_factory.subject_certificate = csr_cert
      extension_factory.issuer_certificate = certificate
  
      csr_cert.add_extension(
        extension_factory.create_extension('basicConstraints', 'CA:FALSE')
      )
      csr_cert.add_extension(
        extension_factory.create_extension('keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')
      )
      csr_cert.add_extension(
        extension_factory.create_extension('subjectKeyIdentifier', 'hash')
      )

      csr_cert.add_extension(
        extension_factory.create_extension("subjectAltName", subject_alt_name(role))
      )

      csr_cert.sign(private_key, OpenSSL::Digest.new('SHA256'))
      csr_cert
    end

    protected

    def subject(role)
      common_name = [
        role.account,
        service_id,
        role.kind,
        role.identifier
      ].join(':')
      OpenSSL::X509::Name.new([['CN', common_name]])
    end

    def service_id
      # CA services have ids like 'conjur/<service_id>/ca'
      @service_id ||= service.identifier.split('/')[1]
    end

    def subject_alt_name(role)
      [
        "DNS:#{leaf_domain_name(role)}",
        "URI:#{spiffe_id(role)}"
      ].join(', ')
    end

    def leaf_domain_name(role)
      role.identifier.split('/').last
    end

    def spiffe_id(role)
      [
        'spiffe://conjur',
        role.account,
        service_id,
        role.kind,
        role.identifier
      ].join('/')
    end

    def private_key
      @private_key ||= load_private_key
    end

    def load_private_key
      if private_key_password?
        OpenSSL::PKey::RSA.new(secret(private_key_var), private_key_password)
      else
        OpenSSL::PKey::RSA.new(secret(private_key_var))
      end
    end

    def private_key_password?
      private_key_password.present?
    end

    def private_key_password
      @private_key_password ||= secret(private_key_password_var)
    end

    def certificate
      # Parse the first certificate in the chain, which should be the
      # intermediate CA certificate
      @certificate ||= OpenSSL::X509::Certificate.new(secret(certificate_chain_var))
    end
  
    def max_ttl
      ISO8601::Duration.new(@service.annotation('ca/max_ttl')).to_seconds
    end

    private
        
    def certificate_chain_var
      @service.annotation('ca/certificate-chain')
    end

    def private_key_var
      @service.annotation('ca/private-key')
    end

    def private_key_password_var
      @service.annotation('ca/private-key-password')
    end

    def secret(name)
      Resource[secret_id(name)]&.secret&.value
    end

    def secret_id(name)
      [service.account, 'variable', name].join(':')
    end
  end
end
