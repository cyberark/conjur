module Repos
  class ConjurCA

    # Generates a CA certificate and key and store them in Conjur variables.  
    def self.create(resource_id)
      ca_info = ::Conjur::CaInfo.new(resource_id)
      ca = ::Util::OpenSsl::CA.from_subject(ca_info.cert_subject)
      Secret.create(resource_id: ca_info.cert_id, value: ca.cert.to_pem)
      Secret.create(resource_id: ca_info.key_id, value: ca.key.to_pem)
      ca.cert
    end

    # Initialize stored CA from Conjur resource_id
    #
    def self.ca(resource_id)
      ca_info = ::Conjur::CaInfo.new(resource_id)
      ca_cert_id = ca_info.cert_id
      ca_key_id = ca_info.key_id
      ca_secrets = fetch_required_secrets.(resource_ids: [ca_cert_id, ca_key_id])
      stored_cert = ca_secrets[ca_cert_id]
      stored_key = ca_secrets[ca_key_id]
      ca_cert = OpenSSL::X509::Certificate.new(stored_cert)
      ca_key = OpenSSL::PKey::RSA.new(stored_key)
      ::Util::OpenSsl::CA.new(ca_cert, ca_key)
    end

    def self.fetch_required_secrets
      @fetch_required_secrets ||= ::Conjur::FetchRequiredSecrets.new
    end
  end
end
