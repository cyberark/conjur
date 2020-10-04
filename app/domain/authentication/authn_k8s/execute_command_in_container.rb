# frozen_string_literal: true

require 'command_class'
require 'uri'
require 'websocket'
require 'rubygems/package'

require 'active_support/time'
require 'websocket-client-simple'

module Authentication
  module AuthnK8s

    ExecuteCommandInContainer ||= CommandClass.new(
      dependencies: {
        env:               ENV,
        websocket_client:  WebSocket::Client::Simple,
        message_log_class: MessageLog,
        validate_message:  MessageLog::ValidateMessage.new,
        logger:            Rails.logger
      },
      inputs:       %i(k8s_object_lookup pod_namespace pod_name container cmds body stdin)
    ) do

      extend Forwardable
      def_delegators :@k8s_object_lookup, :kube_client

      DEFAULT_KUBE_EXEC_COMMAND_TIMEOUT = 5

      def call
        init_ws_client
        add_websocket_event_handlers
        wait_for_close_message
        verify_channel_is_closed
        verify_error_stream_is_empty
        websocket_messages
      end

      def on_open(ws_client, stdin, body)
        hs       = ws_client.handshake
        hs_error = hs.error

        if hs_error
          # Add the error to the stream instead of raising it so we continue to
          # receive other messages. At the end of this class run we will verify
          # the stream to see if any errors were written
          ws_client.emit(
            :error,
            Errors::Authentication::AuthnK8s::WebSocketHandshakeError.new(
              hs_error.inspect
            )
          )
          return
        end

        @logger.debug(
          LogMessages::Authentication::AuthnK8s::PodChannelOpen.new(@pod_name)
        )

        return unless stdin

        # stdin was provided. We send it to the client.

        data = WebSocketMessage.channel_byte('stdin') + body
        ws_client.send(data)

        # We close the socket and don't wait for the other side to close it
        # so that we can finish handling the request quickly and don't leave the
        # Conjur server hanging. If an error occurred it will be written to
        # the client container logs.
        ws_client.send(nil, type: :close)
      end

      def on_message(msg, ws_client)
        ws_msg = WebSocketMessage.new(msg)

        msg_type = ws_msg.type
        msg_data = ws_msg.data

        case msg_type
        when :binary
          @logger.debug(
            LogMessages::Authentication::AuthnK8s::PodChannelData.new(
              @pod_name, ws_msg.channel_name, msg_data
            )
          )
          @validate_message.call(ws_msg)
          @message_log.save_message(ws_msg)
        when :close
          @logger.debug(
            LogMessages::Authentication::AuthnK8s::PodMessageData.new(
              @pod_name, "close", msg_data
            )
          )
          ws_client.close
        end
      end

      def on_close
        @channel_closed = true
        @logger.debug(
          LogMessages::Authentication::AuthnK8s::PodChannelClosed.new(@pod_name)
        )
      end

      def on_error(err)
        @channel_closed = true

        error_info = err.inspect
        @logger.debug(
          LogMessages::Authentication::AuthnK8s::PodError.new(@pod_name, error_info)
        )
        @message_log.save_error_string(error_info)
      end

      private

      def init_ws_client
        @channel_closed = false
        # We need to initialize the message log here instead of in the dependencies
        # so that each instance of ExecuteCommandInContainer will have its own log
        @message_log = @message_log_class.new
        ws_client
      end

      def ws_client
        @ws_client ||= @websocket_client.connect(server_url, headers: headers)
      end

      def add_websocket_event_handlers
        # We need to set these params so the handlers will call this class's methods,
        # using this class's members.
        # If we use 'self' inside the curly brackets it will be try to use methods
        # of the class WebSocket::Client::Simple::Client.
        kube               = self
        stdin              = @stdin
        body               = @body
        ws_client_instance = ws_client

        ws_client.on(:open) { kube.on_open(ws_client_instance, stdin, body) }
        ws_client.on(:message) { |msg| kube.on_message(msg, ws_client_instance) }
        ws_client.on(:close) { kube.on_close }
        ws_client.on(:error) { |err| kube.on_error(err) }
      end

      def wait_for_close_message
        (timeout / 0.1).to_i.times do
          break if @channel_closed
          sleep 0.1
        end
      end

      def verify_channel_is_closed
        unless @channel_closed
          raise Errors::Authentication::AuthnK8s::ExecCommandTimedOut.new(
            timeout,
            @container,
            @pod_name
          )
        end
      end

      def verify_error_stream_is_empty
        error_stream = @message_log.messages[:error]
        return if error_stream.nil? || error_stream.empty?
        raise Errors::Authentication::AuthnK8s::ExecCommandError.new(
          @container,
          @pod_name,
          websocket_error(error_stream)
        )
      end

      def server_url
        api_uri  = kube_client.api_endpoint
        base_url = "wss://#{api_uri.host}:#{api_uri.port}"
        path     = "/api/v1/namespaces/#{@pod_namespace}/pods/#{@pod_name}/exec"

        base_query_string_parts = %W(container=#{CGI.escape(@container)} stderr=true stdout=true)
        stdin_part              = @stdin ? ['stdin=true'] : []
        cmds_part               = @cmds.map { |cmd| "command=#{CGI.escape(cmd)}" }
        query_string            = (
        base_query_string_parts + stdin_part + cmds_part
        ).join("&")

        "#{base_url}#{path}?#{query_string}"
      end

      def headers
        @headers ||= kube_client.headers.clone
      end

      def websocket_error(msg)
        return 'The server returned a blank error message' if msg.blank?
        msg.to_s
      end

      def websocket_messages
        @message_log.messages
      end

      def timeout
        return @timeout if @timeout

        kube_timeout = @env["KUBE_EXEC_COMMAND_TIMEOUT"]
        not_provided = kube_timeout.to_s.strip.empty?
        default      = DEFAULT_KUBE_EXEC_COMMAND_TIMEOUT
        # If the value of KUBE_EXEC_COMMAND_TIMEOUT is not an integer it will be zero
        @timeout = not_provided ? default : kube_timeout.to_i
      end
    end
  end
end
