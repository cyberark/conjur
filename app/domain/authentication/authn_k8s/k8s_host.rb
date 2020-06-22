# Represents a K8s host, typically created from a CSR or a Cert.
#
# This is not to be confused with Conjur model host.  It exists purely to
# encapsulate logic about how to translate K8s host info into a Conjur host id.
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

      def self.from_csr(account:, service_name:, csr:)
        cn = csr.common_name
        unless cn
          raise Errors::Authentication::AuthnK8s::CSRMissingCNEntry.new(
            csr.subject_to_s,
            csr.spiffe_id.to_s
          )
        end
        new(account: account, service_name: service_name, common_name: cn)
      end

      def self.from_cert(account:, service_name:, cert:)
        smart_cert = ::Util::OpenSsl::X509::SmartCert.new(cert)
        cn = smart_cert.common_name
        unless cn
          raise Errors::Authentication::AuthnK8s::CertMissingCNEntry.new(
            smart_cert.smart_subject.to_s,
            smart_cert.san.to_s
          )
        end
        new(account: account, service_name: service_name, common_name: cn)
      end

      def initialize(account:, service_name:, common_name:)
        @account      = account
        @service_name = service_name
        @common_name  = CommonName.new(common_name)
      end

      def conjur_host_id
        host_id = "#{@account}:" + @common_name.k8s_host_name.sub('host/', 'host:')
        Rails.logger.debug(
          LogMessages::Authentication::AuthnK8s::HostIdFromCommonName.new(host_id)
        )
        host_id
      end

      def k8s_host_name
        @common_name.k8s_host_name
      end
    end
  end
end
