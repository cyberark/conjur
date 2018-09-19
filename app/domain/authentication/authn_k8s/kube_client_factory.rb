require 'kubeclient'

#TODO make it class that accepts env, so the validation is only done once
# That is, this is a really an object whose ctor dependency is ENV, and
# where the validation is done at construction.  `client` then becomes
# a method on that constructed object
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

      class << self
        private

        def validate_serviceaccount_dir_exists!
          valid = File.exists?(SERVICEACCOUNT_DIR)
          raise MissingServiceAccountDir, SERVICEACCOUNT_DIR unless valid
        end

        def validate_env_variables!
          EXPECTED_ENV_VARS.each { |v| raise MissingEnvVar, v unless ENV[v] }
        end

        def host_url
          "https://#{ENV['KUBERNETES_SERVICE_HOST']}:#{ENV['KUBERNETES_SERVICE_PORT']}"
        end

        def options
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
end
