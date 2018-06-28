module Authentication
  module AuthnK8s
    module KubectlClient
      extend self
      
      KUBERNETES_SERVICEACCOUNT_DIR = '/var/run/secrets/kubernetes.io/serviceaccount'

      def client api: "api", version: "v1"
        raise "Kubernetes serviceaccount dir #{KUBERNETES_SERVICEACCOUNT_DIR} does not exist" unless File.exists?(KUBERNETES_SERVICEACCOUNT_DIR)
        %w(KUBERNETES_SERVICE_HOST KUBERNETES_SERVICE_PORT).each do |var|
          raise "Expected environment variable #{var} is not set" unless ENV[var]
        end

        url = "https://#{ENV['KUBERNETES_SERVICE_HOST']}:#{ENV['KUBERNETES_SERVICE_PORT']}"
        token_args = {
          auth_options: {
            bearer_token_file: File.join(KUBERNETES_SERVICEACCOUNT_DIR, 'token')
          }
        }

        ssl_args = {
          ssl_options: {
            ca_file: File.join(KUBERNETES_SERVICEACCOUNT_DIR, 'ca.crt'),
            verify_ssl: OpenSSL::SSL::VERIFY_PEER
          }
        }
        Kubeclient::Client.new [ url, api ].join('/'), version, ssl_args.merge(token_args)
      end
    end
  end
end
