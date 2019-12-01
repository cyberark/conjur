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
      "#{variable_id_prefix}/ca/cert"
    end

    def key_id
      "#{variable_id_prefix}/ca/key"
    end

    def cert_subject
      "/CN=#{common_name}/OU=Conjur Kubernetes CA/O=#{account}"
    end

    def common_name
      @resource_id.tr('/', '.')
    end

    def account
      resource_id_parts.first
    end

    private

    def variable_id_prefix
      "#{account}:variable:#{service_name}"
    end

    def service_name
      resource_id_parts.last
    end

    def resource_id_parts
      @resource_id_parts ||= @resource_id.split(':')
    end
  end
end
