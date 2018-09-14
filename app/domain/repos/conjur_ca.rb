module Repos
  class ConjurCA

    # Generates a CA certificate and key and store them in Conjur variables.  
    def self.create(resource_id)
      #TODO:
      Rails.logger.debug("jonah1 creating #{resource_id}")
      ca_info = ::Conjur::CaInfo.new(resource_id)
      Rails.logger.debug("ca_info #{ca_info.inspect}")
      ca = ::Util::OpenSsl::CA.from_subject(ca_info.cert_subject)
      Secret.create(resource_id: ca_info.cert_id, value: ca.cert.to_pem)
      Secret.create(resource_id: ca_info.key_id, value: ca.key.to_pem)
    end

    # Initialize stored CA from Conjur resource_id
    #
    def self.ca(resource_id)
      #TODO:
      Rails.logger.debug("jonah1 looking up #{resource_id}")
      ca_info = ::Conjur::CaInfo.new(resource_id)
      Rails.logger.debug("ca_info #{ca_info.inspect}")
      stored_cert = Resource[ca_info.cert_id].last_secret.value
      stored_key = Resource[ca_info.key_id].last_secret.value
      ca_cert = OpenSSL::X509::Certificate.new(stored_cert)
      ca_key = OpenSSL::PKey::RSA.new(stored_key)
      ::Util::OpenSsl::CA.new(ca_cert, ca_key)
    end

  end
end
