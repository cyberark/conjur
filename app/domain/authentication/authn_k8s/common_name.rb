# Represents the CN of a K8s Host.
#

#NOTE: these are here for when we gemify this
#require 'app/domain/util/open_ssl/x509/smart_cert'
#require 'app/domain/util/open_ssl/x509/smart_csr'

module Authentication
  module AuthnK8s
    class CommonName

      def self.from_host_resource_name(name)
        common_name = name.tr('/', '.')
        new(common_name)
      end

      def initialize(common_name)
        @common_name  = common_name
      end

      def k8s_host_name
        @k8s_host_name ||= @common_name.split('.').join('/')
      end

      def to_s
        @common_name
      end
    end
  end
end
