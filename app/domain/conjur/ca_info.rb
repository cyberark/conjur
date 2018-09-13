# Represents the names and other information for a Conjur CA based on a
# resource.  In K8s, eg, we have CAs for each webservice resource.
#
# Encapsulates logic around naming conventions for the cert and key resources,
# which can be considered child resources, as well as how to construct the
# certificate subject string.
#
module Conjur

  class CaInfo
    def initialize(resource_id)
      @resource_id = resource_id
    end

    def cert_id
      "#{account}:variable:#{service_id}/ca/cert"
    end

    def key_id
      #{account}:variable:#{service_id}/ca/key"
    end

    def cert_subject
      "/CN=#{common_name}/OU=Conjur Kubernetes CA/O=#{account}"
    end

    def common_name
      @resource_id.gsub('/', '.')
    end

    def account
      @resource_id.split(':').first
    end

    private

    def service_id
      @resource_id.split(':').last
    end
  end
end
