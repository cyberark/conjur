# frozen_string_literal: true

class CertificateAuthorityController < RestController

  def sign_host
    raise RecordNotFound.new("No CA #{service_id}") unless ca_resource
    raise RecordNotFound.new("No Host #{host_id}") unless host

    raise Forbidden.new unless current_user.allowed_to?('sign', ca_resource)
    raise Forbidden.new('Requestor is not CSR host') unless requestor_is_host?
    raise Forbidden.new('CSR cannot be verified') unless csr.verify(csr.public_key)
    raise Forbidden.new('CSR CN does not match host') unless host_name_matches?(csr)
    
    certificate = sign_csr

    render json: {
      id: host_full_id,
      created_at: certificate.not_before,
      expires_at: certificate.not_after,
      certificate: certificate.to_pem
    }
  end

  protected

  def host_name_matches?(csr)
    csr_info = csr.subject.to_a.inject({}) do |r, s|
        r.merge!(s[0] => s[1])
      end

    csr_info["CN"] == host_id.split('/').last
  end

  def requestor_is_host?
    current_user.id == host_full_id
  end

  def host_full_id
    [account, 'host', host_id].join(':')
  end

  def sign_csr
    csr_cert = OpenSSL::X509::Certificate.new
    csr_cert.serial = 0
    csr_cert.version = 2
    csr_cert.not_before = Time.now
    csr_cert.not_after = Time.now + csr_cert_ttl

    csr_cert.subject = csr.subject
    csr_cert.public_key = csr.public_key
    csr_cert.issuer = ca_cert.subject

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = csr_cert
    extension_factory.issuer_certificate = ca_cert

    csr_cert.add_extension(
      extension_factory.create_extension('basicConstraints', 'CA:FALSE')
    )
    csr_cert.add_extension(
      extension_factory.create_extension('keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')
    )
    csr_cert.add_extension(
      extension_factory.create_extension('subjectKeyIdentifier', 'hash')
    )

    csr_cert.sign ca_key, OpenSSL::Digest::SHA256.new

    csr_cert
  end

  def csr_cert_ttl
    [ttl, ca_max_ttl].map { |ttl| ISO8601::Duration.new(ttl).to_seconds }.min
  end

  def ca_cert
    secret_id = [account, 'variable', ca_cert_variable].join(':')
    @ca_cert ||= OpenSSL::X509::Certificate.new Resource[secret_id].secret.value
  end

  def ca_key
    secret_id = [account, 'variable', ca_key_variable].join(':')
    @ca_key ||= OpenSSL::PKey::RSA.new Resource[secret_id].secret.value
  end

  def ca_cert_variable
    ca_resource.annotation('ca/certificate-chain')
  end

  def ca_key_variable
    ca_resource.annotation('ca/private-key')
  end

  def ca_max_ttl
    ca_resource.annotation('ca/max_ttl')
  end
  
  def csr
    @csr ||= OpenSSL::X509::Request.new (params[:csr] + "\n")
  end

  def ca_resource
    identifier = Sequel.function(:identifier, :resource_id)
    kind = Sequel.function(:kind, :resource_id)
    account = Sequel.function(:account, :resource_id)

    @ca_resource ||= Resource
                        .where(
                          identifier => "conjur/#{service_id}/ca", 
                          kind => "webservice",
                          account => account
                        )
                        .first
  end

  def host
    identifier = Sequel.function(:identifier, :resource_id)
    kind = Sequel.function(:kind, :resource_id)
    account = Sequel.function(:account, :resource_id)

    @host ||= Resource
                        .where(
                          identifier => host_id, 
                          kind => "host",
                          account => account
                        )
                        .first
  end

  def service_id
    params[:service_id]
  end

  def account
    params[:account]
  end

  def host_id
    params[:identifier]
  end

  def ttl
    params[:ttl]
  end
end
