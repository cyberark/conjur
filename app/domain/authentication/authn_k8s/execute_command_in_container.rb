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
        env:                           ENV,
        websocket_client:              WebSocket::Client::Simple,
        ws_client_event_handler_class: WebSocketClientEventHandler,
        message_log_class:             MessageLog,
        validate_message:              MessageLog::ValidateMessage.new,
        logger:                        Rails.logger
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

      private

      def init_ws_client
        ws_client
        ws_client_event_handler
      end

      def ws_client
        @ws_client ||= @websocket_client.connect(server_url, headers: headers)
      end

      def ws_client_event_handler
        @ws_client_event_handler ||= @ws_client_event_handler_class.new(
          ws_client:        ws_client,
          stdin:            @stdin,
          body:             @body,
          pod_name:         @pod_name,
          validate_message: @validate_message,
          message_log:      @message_log_class.new,
          logger:           @logger
        )
      end

      def add_websocket_event_handlers
        # We need to set this as if we'll use @ws_client_event_handler inside
        # the curly brackets it will look for such a member in the websocket_client
        # class
        ws_client_event_handler = @ws_client_event_handler
        main_thread_tags        = @logger.formatter.current_tags
        logger                  = @logger

        ws_client.on(:open) do
          # Add log tags (origin, thread id, etc.) to sub-thread as they are not
          # passed automatically. We append the sub-thread id to the main one so
          # we can easily know the flow from the logs and connect between the threads
          tid             = syscall(186)
          sub_thread_tags = main_thread_tags.map do |x|
            x.start_with?("tid=") ? "#{x}=>#{tid}" : x
          end
          logger.formatter.current_tags.replace sub_thread_tags
          ws_client_event_handler.on_open
        end
        ws_client.on(:message) { |msg| ws_client_event_handler.on_message(msg) }
        ws_client.on(:close) { ws_client_event_handler.on_close }
        ws_client.on(:error) { |err| ws_client_event_handler.on_error(err) }
      end

      def wait_for_close_message
        (timeout / 0.1).to_i.times do
          break if ws_client_event_handler.channel_closed
          sleep 0.1
        end
      end

      def verify_channel_is_closed
        return if ws_client_event_handler.channel_closed

        raise Errors::Authentication::AuthnK8s::ExecCommandTimedOut.new(
          timeout,
          @container,
          @pod_name
        )
      end

      def verify_error_stream_is_empty
        error_stream = ws_client_event_handler.message_log.messages[:error]
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
        ws_client_event_handler.message_log.messages
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
