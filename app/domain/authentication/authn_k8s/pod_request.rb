# Represents a k8s pod request: either a request to have a certificate injected
# into it, or a request for authentication.  It's used by ValidatePodRequest to
# perform basic validations on the request.
#
module Authentication
  module AuthnK8s

    class PodRequest
      attr_reader :service_id, :k8s_host, :spiffe_id

      # @param service_id [String] Id of webservice the host wants to access.
      #   This is only the very last part of the full conjur resource id. See
      #   the Webservice class for more.
      # @param k8s_host [K8sHost] Value object representing k8 host info
      # @param spiffe_id [SpiffeId] Value object representing a spiffe id
      #
      def initialize(service_id:, k8s_host:, spiffe_id:)
        @service_id = service_id
        @k8s_host = k8s_host
        @spiffe_id = spiffe_id
      end
    end

  end
end
