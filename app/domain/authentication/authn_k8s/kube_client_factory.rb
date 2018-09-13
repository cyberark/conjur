require 'kubeclient'

#TODO make it class that accepts env, so the validation is only done once
#
module Authentication
  module AuthnK8s
    module KubeClientFactory

      MissingServiceAccountDir = ::Util::ErrorClass.new(
        "Kubernetes serviceaccount dir '{0}' does not exist")

      MissingEnvVar = ::Util::ErrorClass.new(
        "Expected ENV variable '{0}' is not set")
      
      SERVICEACCOUNT_DIR = '/var/run/secrets/kubernetes.io/serviceaccount'
      EXPECTED_ENV_VARS = %w[KUBERNETES_SERVICE_HOST KUBERNETES_SERVICE_PORT]

      def self.client(api: 'api', version: 'v1')
        validate_serviceaccount_dir_exists!
        validate_env_variables!
        full_url = "#{host_url}/#{api}"
        Kubeclient::Client.new(full_url, version, options)
      end

      private

      def self.validate_serviceaccount_dir_exists!
        valid = File.exists?(SERVICEACCOUNT_DIR)
        raise MissingServiceAccountDir, SERVICEACCOUNT_DIR unless valid
      end

      def self.validate_env_variables!
        EXPECTED_ENV_VARS.each { |v| raise MissingEnvVar, v unless ENV[v] }
      end

      def self.host_url
        "https://#{ENV['KUBERNETES_SERVICE_HOST']}:#{ENV['KUBERNETES_SERVICE_PORT']}"
      end

      def self.options
        {
          auth_options: {
            bearer_token_file: File.join(SERVICEACCOUNT_DIR, 'token')
          },
          ssl_options: {
            ca_file: File.join(SERVICEACCOUNT_DIR, 'ca.crt'),
            verify_ssl: OpenSSL::SSL::VERIFY_PEER
          }
        }
      end

    end
  end
end
