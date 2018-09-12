require 'uri'
require 'websocket'
require 'rubygems/package'

require 'active_support/time'
require 'websocket-client-simple'

module Authentication
  module AuthnK8s
    CommandTimedOut = ::Util::ErrorClass.new(
      "Command timed out in container '{0}' of pod '{1}'"
    )

    # Utility class for processing WebSocket messages.
    class WebSocketMessage
      class << self
        def channel_byte(channel_name)
          channel_number_from_name(channel_name).chr
        end
      end
      
      def initialize(msg)
        @msg = msg
      end

      def type
        @msg.type
      end
      
      def data
        @msg.data[1..-1]
      end

      def channel_name
        channel_names[channel_number]
      end
      
      def channel_number
        unless @msg.respond_to?(:data)
          return self.class.channel_number_from_name('error') 
        end
        
        @msg.data[0..0].bytes.first
      end

      public
      
      def channel_number_from_name(channel_name)
        channel_names.index(channel_name)
      end

      def channel_names
        %w(stdin stdout stderr error resize)
      end
    end

    # Utility class for storing messages received during websocket communication.
    class MessageLog
      attr_reader :messages
      
      def initialize
        @messages = Hash.new { |hash,key| hash[key] = [] }
      end

      def save_message(wsmsg)
        channel_name = wsmsg.channel_name
        
        unless channel_name
          raise "Unexpected channel: #{wsmsg.channel_number}"
        end
        
        @messages[channel_name.to_sym] << wsmsg.data
      end

      def save_error_string(str)
        @messages[:error] << str
      end
    end
    
    class KubectlExec
      # logger: an object responding to `debug`
      # kubeclient: Kubeclient::Client from "kubeclient" gem
      #
      def initialize(
        pod_name:,
        pod_namespace:,
        logger:,
        kubeclient:,
        container: 'authentication',
        timeout: 5.seconds
      )
        @pod_name = pod_name
        @pod_namespace = pod_namespace
        @container = container
        @timeout = timeout
        @logger = logger
        @kubeclient = kubeclient

        @message_log = MessageLog.new
        @channel_closed = false
      end

      def execute(cmds, body: "", stdin: false)
        url = server_url(cmds, stdin)
        headers = @kubeclient.headers.clone
        ws_client = WebSocket::Client::Simple.connect(url, headers: headers)

        add_websocket_event_handlers(ws_client, body, stdin)

        wait_for_close_message

        raise CommandTimedOut.new(@container, @pod_name) unless @channel_closed
        
        # TODO: raise an `WebsocketServerFailure` here in the case of ws :error

        @message_log.messages
      end
      
      def copy(path, content, mode)
        execute(
          [ 'tar', 'xvf', '-', '-C', '/' ],
          stdin: true,
          body: tar_file_as_string(path, content, mode)
        )
      end
      
      def on_open(ws_client, body, stdin)
        if ws_client.handshake.error
          ws_client.emit(:error, @message_log.messages)
        else
          @logger.debug("Pod #{@pod_name} : channel open")

          if stdin
            data = WebSocketMessage.channel_byte('stdin') + body
            ws_client.send(data)
            ws_client.send(nil, type: :close)
          end
        end
      end

      def on_message(msg, ws_client)
        wsmsg = WebSocketMessage.new(msg)
        
        msg_type = wsmsg.type
        msg_data = wsmsg.data
        
        if msg_type == :binary
          @logger.debug("Pod #{@pod_name}, channel #{wsmsg.channel_name}: #{msg_data}")
          @message_log.save_message(wsmsg)
        elsif msg_type == :close
          @logger.debug("Pod: #{@pod_name}, message: close, data: #{msg_data}")
          ws_client.close
        end
      end
      
      def on_close
        @channel_closed = true
        @logger.debug("Pod #{@pod_name} : channel closed")
      end

      def on_error(err)
        puts("*** error: #{err.inspect}")
        @channel_closed = true
        @logger.debug("Pod #{@pod_name} error : #{err.inspect}")
        @message_log.save_error_string(err.inspect)
      end

      private

      def add_websocket_event_handlers(ws_client, body, stdin)
        kubectl = self
        
        ws_client.on(:open) { kubectl.on_open(ws_client, body, stdin) }
        ws_client.on(:message) { |msg| kubectl.on_message(msg, ws_client) }
        ws_client.on(:close) { kubectl.on_close }
        ws_client.on(:error) { |err| kubectl.on_error(err) }
      end

      def wait_for_close_message
        (@timeout / 0.1).to_i.times do
          break if @channel_closed
          sleep 0.1
        end
      end

      def query_string(cmds, stdin)
        stdin_part = stdin ? ['stdin=true'] : []
        cmds_part = cmds.map { |cmd| "command=#{CGI.escape(cmd)}" }
        (base_query_string_parts + stdin_part + cmds_part).join("&")
      end

      def base_query_string_parts
        [ "container=#{CGI.escape(@container)}", "stderr=true", "stdout=true" ]
      end

      def server_url(cmds, stdin)
        api_uri = @kubeclient.api_endpoint
        base_url = "wss://#{api_uri.host}:#{api_uri.port}"
        path = "/api/v1/namespaces/#{@pod_namespace}/pods/#{@pod_name}/exec"
        query = query_string(cmds, stdin)
        "#{base_url}#{path}?#{query}"
      end

      def tar_file_as_string(path, content, mode)
        tarfile = StringIO.new("")
        
        Gem::Package::TarWriter.new(tarfile) do |tar|
          tar.add_file(path, mode) do |tf|
            tf.write(content)
          end
        end

        tarfile.string
      end

    end
  end
end
