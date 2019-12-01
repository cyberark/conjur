# Represents a K8s host, typically created from a CSR or a Cert.
#
# This is not to be confused with Conjur model host.  It exists purely to
# encapsulate logic about how to translate K8s host info into a Conjur host id,
# and how to break a K8s host into its component parts: namespace, controller,
# object
#
require 'forwardable'

# NOTE: these are here for when we gemify this
# require 'app/domain/util/open_ssl/x509/smart_cert'
# require 'app/domain/util/open_ssl/x509/smart_csr'
# require_relative 'common_name'

module Authentication
  module AuthnK8s
    class K8sHost
      extend Forwardable

      attr_reader :account, :service_name, :csr

      def_delegators :@common_name, :namespace, :controller, :object,
        :k8s_host_name

      def self.from_csr(account:, service_name:, csr:)
        cn = csr.common_name
        raise ArgumentError, 'CSR must have a CN entry' unless cn

        new(account: account, service_name: service_name, common_name: cn)
      end

      def self.from_cert(account:, service_name:, cert:)
        cn = Util::OpenSsl::X509::SmartCert.new(cert).common_name
        raise ArgumentError, 'Certificate must have a CN entry' unless cn

        new(account: account, service_name: service_name, common_name: cn)
      end

      def initialize(account:, service_name:, common_name:)
        @account      = account
        @service_name = service_name
        @common_name  = CommonName.new(common_name)
      end

      def conjur_host_id
        "#{@account}:" + host_name.sub('host/', 'host:')
      end

      def host_name
        @common_name.k8s_host_name
      end

      def namespace_scoped?
        controller == '*' && object == '*'
      end

      def permitted_scope?
        permitted_controllers.include?(controller)
      end

      private

      def permitted_controllers
        @permitted_controllers ||= %w(
          pod service_account deployment stateful_set deployment_config
        )
      end
    end
  end
end
