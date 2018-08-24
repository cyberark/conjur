# frozen_string_literal: true

class CertificateAuthorityController < RestController
  include ActionController::MimeResponds

  def sign
    raise RecordNotFound, "No CA #{service_id}" unless ca_resource

    raise Forbidden unless current_user.allowed_to?('sign', ca_resource)
    raise Forbidden, 'Requestor is not a host' unless requestor_is_host?
    raise Forbidden, 'CSR cannot be verified' unless csr.verify(csr.public_key)
    raise Forbidden, 'CSR CN does not match host' unless host_name_matches?(csr)

    ca = ::CA::CertificateAuthority.new(ca_resource)
    certificate = ca.sign_csr(csr, ttl)

    respond_to do |format|
      format.json do
        render json: {
          certificate: certificate.to_pem
        },
        status: :created
      end

      format.pem do
        render body: certificate.to_pem, content_type: 'application/x-pem-file', status: :created
      end
    end
  end

  protected

  def host_name_matches?(csr)
    csr_info = csr.subject.to_a.inject({}) do |result, (k, v)|
      result.merge!(k => v)
    end

    csr_info['CN'] == host.identifier.split('/').last
  end

  def requestor_is_host?
    current_user.kind == 'host'
  end

  def csr
    @csr ||= OpenSSL::X509::Request.new(params[:csr])
  end

  def ca_resource
    identifier = Sequel.function(:identifier, :resource_id)
    kind = Sequel.function(:kind, :resource_id)
    account = Sequel.function(:account, :resource_id)

    @ca_resource ||= Resource
                     .where(
                       identifier => "conjur/#{service_id}/ca", 
                       kind => 'webservice',
                       account => account
                     )
                     .first
  end

  def host
    @host ||= Resource
              .where(:resource_id => current_user.id)
              .first
  end

  def service_id
    params[:service_id]
  end

  def account
    params[:account]
  end

  def ttl
    ISO8601::Duration.new(params[:ttl]).to_seconds 
  end
end
