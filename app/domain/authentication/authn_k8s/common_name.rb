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
        validate!
      end

      def namespace
        host_name_suffix[-3]
      end

      def controller
        host_name_suffix[-2]
      end

      def object
        host_name_suffix[-1]
      end

      def k8s_host_name
        full_host_name.join('/')
      end

      def to_s
        full_host_name.join('.')
      end

      private

      def validate!
        valid = host_name_suffix.length == 3
        raise ArgumentError, "Invalid K8s host CN: #{@common_name}. " +
              "Must end with namespace.controller.id" unless valid
      end

      def host_name_suffix
        @host_name_suffix ||= full_host_name.last(3)
      end

      def full_host_name
        @full_host_name ||= @common_name.split('.')
      end
    end
  end
end
