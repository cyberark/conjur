require 'command_class'

module Authentication
  module Security
    ProcessRequestProxies = CommandClass.new(
      dependencies: {
        #InputValidation
      },
      inputs: [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :request

      def call
        process_xff_header
      end

      private

      X_FORWARDED_FOR = 'X-Forwarded-For'

      Struct.new("RemoteAddress", :client_ip, :proxy_list)

      def process_xff_header
        remote_addr = request.remote_addr
        xff_header = request.headers[X_FORWARDED_FOR]
        xff_header_ip_list = xff_header.split(/, /) unless xff_header.nil?
        empty_ip_list = xff_header.nil?
        single_ip_in_list = xff_header && xff_header_ip_list.length() == 1
        multi_ips_in_list = xff_header && xff_header_ip_list.length() > 1

        if empty_ip_list
          Struct::RemoteAddress.new(
            remote_addr,
            []
          )
        elsif single_ip_in_list
          Struct::RemoteAddress.new(
            xff_header_ip_list.first,
            [remote_addr]
          )
        elsif multi_ips_in_list
          Struct::RemoteAddress.new(
            xff_header_ip_list.shift,
            xff_header_ip_list.uniq
          )
        end
      end
    end
  end
end

