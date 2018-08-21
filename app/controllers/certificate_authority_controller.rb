# frozen_string_literal: true

class CertificateAuthorityController < RestController

  def sign_host
    raise RecordNotFound.new("No CA #{service_id}") unless ca_resource
    raise RecordNotFound.new("No Host #{host_id}") unless host

    raise Forbidden.new unless current_user.allowed_to?('sign', ca_resource)
    raise Forbidden.new('Requestor is not CSR host') unless requestor_is_host?
    raise Forbidden.new('CSR cannot be verified') unless csr.verify(csr.public_key)
    raise Forbidden.new('CSR CN does not match host') unless host_name_matches?(csr)

    ca = ::CA::CertificateAuthority.new(ca_resource)
    certificate = ca.sign_csr(csr, ttl)

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
    ISO8601::Duration.new(params[:ttl]).to_seconds 
  end
end
