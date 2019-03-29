# frozen_string_literal: true

require 'dry-struct'

module CA
  # A CertificateAuthority is responsible for verifying and signing
  # a certificate request.
  class CertificateAuthority < Dry::Struct

    attribute :webservice, Types.Definition(::CA::Webservice)

    def verify_request(certificate_request)
      verify_command.(certificate_request: certificate_request)
    end

    def sign_certificate(certificate_request)
      sign_command.(certificate_request: certificate_request)
    end

    # @abstract Subclass is expected to implement #verify_command
    # @!method verify_request_command
    #    Returns a command class to verify a CertificateRequest and
    #    return a FormattedCertificate

    # @abstract Subclass is expected to implement #sign_command
    # @!method verify_request_command
    #    Returns a command class to sign a CertificateRequest and
    #    return a Certificate object
  end
end
