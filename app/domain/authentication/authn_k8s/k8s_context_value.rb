module Authentication
  module AuthnK8s
    # K8sContextValue attempts to retrieve a value from a file, falling back to
    # a value stored in a Conjur variable.
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
