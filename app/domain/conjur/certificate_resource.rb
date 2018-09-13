# Represents a Conjur resource that has an associated CA -- A CA itself
# consists of a certificate and its private key.
#
# This simply decorates a model Resource object, giving it new methods relevant
# to "certificate" resources.
#
# Encapsulates logic around naming conventions for the cert and key resources,
# which can be considered child resources, as well as how to construct the
# certificate subject string.
#
module Conjur
  class CertificateResource < SimpleDelegator

    def cert_id
      "#{id}/ca/cert"
    end

    def key_id
      "#{id}/ca/key"
    end

    def cert_subject
      "/CN=#{common_name}/OU=Conjur Kubernetes CA/O=#{account}"
    end

    def common_name
      id.gsub('/', '.')
    end
  end
end
