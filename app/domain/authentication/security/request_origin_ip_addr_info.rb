module Authentication
  module Security
    class RequestOriginIpAddrInfo
      attr_reader :client_ip, :xff_ip_list

      def initialize(client_ip, xff_ip_list)
        @client_ip = client_ip
        @xff_ip_list = xff_ip_list
      end
    end
  end
end
