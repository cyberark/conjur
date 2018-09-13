module Repos
  class ConjurCA

    # Generates a CA certificate and key and store them in Conjur variables.  
    def self.create(service_id)
      Rails.logger.debug("jonah0 creating CA for #{service_id}")
      cr = cert_resource(service_id)
      Rails.logger.debug(cr.inspect)
      Rails.logger.debug(cr.cert_id)
      ca = ::Util::OpenSsl::CA.from_subject(cr.cert_subject)
      Secret.create(resource_id: cr.cert_id, value: ca.cert.to_pem)
      Secret.create(resource_id: cr.key_id, value: ca.key.to_pem)
    end

    # Initialize CA from Conjur variables
    #
    # Note: This repo accepts a domain object (a resource model object)
    #       and returns a domain object.
    #
    def self.ca(service_id)
      Rails.logger.debug("jonah1 creating CA for #{service_id}")
      cr = cert_resource(service_id)
      Rails.logger.debug("jonah1 #{cr.inspect}")
      Rails.logger.debug("jonah1 #{cr.cert_id}")
      stored_cert = Resource[cr.cert_id.to_s].last_secret.value
      stored_key = Resource[cr.key_id.to_s].last_secret.value
      ca_cert = OpenSSL::X509::Certificate.new(stored_cert)
      ca_key = OpenSSL::PKey::RSA.new(stored_key)
      ::Util::OpenSsl::CA.new(ca_cert, ca_key)
    end

    def self.cert_resource(service_id)
      resource = Resource[service_id]
      ::Conjur::CertificateResource.new(resource)
    end

  end
end
