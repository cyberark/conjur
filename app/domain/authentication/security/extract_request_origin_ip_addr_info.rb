require 'command_class'

module Authentication
  module Security
    ExtractRequestOriginIpAddrInfo = CommandClass.new(
      dependencies: {
        # InputValidation
      },
      inputs: [:request]
    ) do

      extend Forwardable
      def_delegators :@request, :remote_addr, :headers

      def call
        extract_request_origin_addr_info
      end

      private

      X_FORWARDED_FOR_HEADER_NAME = 'X-Forwarded-For'

      def extract_request_origin_addr_info
        xff_header = headers[X_FORWARDED_FOR_HEADER_NAME]
        xff_header_ip_list = (nil_or_empty? xff_header) ? [] : xff_header.to_s.split(/, /).uniq
        xff_ip_list_length = xff_header_ip_list.length

        if xff_header_ip_list.empty?
          RequestOriginIpAddrInfo.new(
            remote_addr,
            []
          )
        elsif xff_ip_list_length == 1
          RequestOriginIpAddrInfo.new(
            xff_header_ip_list.first,
            [remote_addr]
          )
        elsif xff_ip_list_length > 1
          client_ip = xff_header_ip_list.shift
          xff_header_ip_list << remote_addr

          RequestOriginIpAddrInfo.new(
            client_ip,
            xff_header_ip_list
          )
        end
      end

      def nil_or_empty?(str)
        str.nil? || str.empty?
      end
    end
  end
end
