# frozen_string_literal: true

# Responsible for API calls to interact with a Conjur-configured
# certificate authority (CA) service
class CertificateAuthorityController < RestController
  include ActionController::MimeResponds
  include BodyParser

  before_action :verify_ca_exists
  before_action :verify_role
  before_action :verify_kind
 
  def sign_certificate     
    formatted_certificate = signed_certificate.to_formatted
    render(
      body: formatted_certificate.to_s,
      content_type: formatted_certificate.content_type, 
      status: :created
    )
  end

  protected

  def verify_role
    can_sign = current_user.allowed_to?('sign', ca_resource)
    raise Forbidden, "Role is not authorized to request signed certificate." unless can_sign
  end

  def verify_kind
    raise ArgumentError, "Invalid certificate kind: '#{certificate_kind}'" unless certificate_authority.present?
  end

  def verify_ca_exists
    raise RecordNotFound, "There is no certificate authority with ID: #{service_id}" unless ca_resource
  end

  private

  def signed_certificate
    certificate_authority.sign.new.(
      issuer: issuer,
      certificate_request: certificate_request
    )
  end

  def certificate_request
    symbolized_params = params.to_unsafe_h.symbolize_keys
    certificate_authority
      .certificate_request
      .from_hash(symbolized_params.merge(role: current_user))
  end

  def certificate_authority
    @certificate_authority ||= ::CA.from_type(certificate_kind)
  end

  def certificate_kind
    (params[:kind] || 'x509').downcase.to_sym
  end

  def issuer
    @issuer ||= certificate_authority.issuer.from_resource(ca_resource)
  end

  def ca_resource
    @ca_resource ||= Resource["#{account}:webservice:conjur/ca/#{service_id}"]
  end

  def service_id
    params[:service_id]
  end

  def account
    params[:account]
  end
end
