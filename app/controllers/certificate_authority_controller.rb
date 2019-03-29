# frozen_string_literal: true

# Responsible for API calls to interact with a Conjur-configured
# certificate authority (CA) service
class CertificateAuthorityController < RestController
  include ActionController::MimeResponds
  include BodyParser

  before_action :verify_ca_exists
  before_action :verify_role
  before_action :verify_kind
  before_action :verify_request
 
  def sign_certificate
    signed_certificate = certificate_authority.sign_certificate(certificate_request)
    formatted_certificate = signed_certificate.to_formatted

    render(
      body: formatted_certificate.to_s,
      content_type: formatted_certificate.content_type, 
      status: :created
    )
  end

  protected

  def available_ca_types
    {
      x509: CA::X509::CertificateAuthority
    }
  end

  def verify_role
    raise Forbidden, "Host is not authorized to sign." unless webservice.can_sign?(current_user)
  end

  def verify_kind
    raise ArgumentError, "Invalid certificate kind: '#{certificate_kind}'" unless available_ca_types.key?(certificate_kind)
  end

  def verify_ca_exists
    raise RecordNotFound, "There is no certificate authority with ID: #{service_id}" unless webservice.exists?
  end

  def verify_request
    certificate_authority.verify_request(certificate_request)
  end

  private

  def certificate_request
    ::CA::CertificateRequest.new(
      kind: certificate_kind, 
      params: params, 
      role: current_user
    )
  end

  def certificate_authority
    @certificate_authority ||= available_ca_types[certificate_kind].new(webservice: webservice)
  end

  def certificate_kind
    (params[:kind] || 'x509').downcase.to_sym
  end

  def webservice
    @webservice ||= ::CA::Webservice.load(account, service_id)
  end

  def service_id
    params[:service_id]
  end

  def account
    params[:account]
  end
end
