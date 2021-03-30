module Authentication
  module AuthnK8s
    # K8sContextValue attempts to retrieve a value from a file, falling back to
    # a value stored in a Conjur variable.

    # In the context of retrieving service account tokens, this arrangement
    # allows Conjur instances running inside a K8s cluster to use different
    # service account tokens (defined on their file system) while any instances
    # running outside the cluster are forced to use the same service account
    # token (defined in policy).

    # If we were to flip the priorities such that policy was preferred, it would
    # force all Conjur instances running both outside and inside a K8s cluster
    # to use the service account token defined in policy, which likely would not
    # be the desired behavior.
    class K8sContextValue
      def self.get webservice, file_name, variable_id
        return File.read(file_name) if File.exist?(file_name)

        webservice.variable(variable_id).secret.value if webservice.present?
      rescue
        nil
      end
    end
  end
end
