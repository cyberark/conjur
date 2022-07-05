# frozen_string_literal: true

require 'command_class'
require 'uri'
require 'websocket'
require 'rubygems/package'

require 'active_support/time'
require 'timeout'

module Authentication
  module AuthnK8s

    ExecuteCommandInContainer ||= CommandClass.new(
      dependencies: {
        timeout: ENV['KUBE_EXEC_COMMAND_TIMEOUT'],
        websocket_client: WebSocketClient,
        ws_client_event_handler_class: WebSocketClientEventHandler,
        message_log_class: MessageLog,
        validate_message: MessageLog::ValidateMessage.new,
        logger: Rails.logger
      },
      inputs: %i[k8s_object_lookup pod_namespace pod_name container cmds body stdin]
    ) do
      DEFAULT_TIMEOUT_SEC = 5

      extend(Forwardable)
      def_delegators(:@k8s_object_lookup, :kube_client)

      def call
        init_ws_client
        add_websocket_event_handlers
        wait_for_close_message
        verify_error_stream_is_empty
        websocket_messages
      end

      private

      def init_ws_client
        ws_client
        ws_client_event_handler
      end

      def ws_client
        @ws_client ||= @websocket_client.connect(
          ws_exec_url,
          {
            headers: headers,
            cert_store: @k8s_object_lookup.cert_store
          }
        )
      end

      def ws_client_event_handler
        @close_event_queue = Queue.new
        @ws_client_event_handler ||= @ws_client_event_handler_class.new(
          close_event_queue: @close_event_queue,
          ws_client: ws_client,
          stdin: @stdin,
          body: @body,
          pod_name: @pod_name,
          validate_message: @validate_message,
          message_log: @message_log_class.new,
          logger: @logger
        )
      end

      def add_websocket_event_handlers
        # We need to set this as if we'll use @ws_client_event_handler inside
        # the curly brackets it will look for such a member in the websocket_client
        # class
        ws_client_event_handler = @ws_client_event_handler
        main_thread_tags = @logger.formatter.current_tags
        logger = @logger

        ws_client.on(:open) do
          # Add log tags (origin, thread id, etc.) to sub-thread as they are not
          # passed automatically. We append the sub-thread id to the main one so
          # we can easily know the flow from the logs and connect between the threads
          tid = syscall(186)
          sub_thread_tags = main_thread_tags.map do |x|
            x.start_with?("tid=") ? "#{x}=>#{tid}" : x
          end
          logger.formatter.current_tags.replace(sub_thread_tags)
          ws_client_event_handler.on_open
        end
        ws_client.on(:message) { |msg| ws_client_event_handler.on_message(msg) }
        ws_client.on(:close) { ws_client_event_handler.on_close }
        ws_client.on(:error) { |err| ws_client_event_handler.on_error(err) }
      end

      def wait_for_close_message
        Timeout.timeout(timeout) { @close_event_queue.pop }
      rescue Timeout::Error
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

      def ws_exec_url
        api_uri = kube_client.api_endpoint.clone # contains /api path prefix

        # append pod exec path
        api_uri.path += "/v1/namespaces/#{@pod_namespace}/pods/#{@pod_name}/exec"

        # populate query params
        api_uri.query = ws_exec_query_params(String(api_uri.query))

        api_uri.to_s
      end

      def ws_exec_query_params query
        base_query_string_parts = [["container", @container], ["stderr", "true"], ["stdout", "true"]]
        stdin_part = @stdin ? [['stdin', 'true']] : []
        cmds_part = @cmds.map { |cmd| ["command", cmd] }
        query_ar = URI.decode_www_form(query) + base_query_string_parts + stdin_part + cmds_part
        URI.encode_www_form(query_ar)
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

      # Timeout logic is as follows:
      # 1. Use default when no timeout is given.
      # 2. Use given value if it can be coerced into an integer.
      # 3. If coercion fails, warn and use default.
      def timeout
        return @validated_timeout if @validated_timeout

        return @validated_timeout = DEFAULT_TIMEOUT_SEC unless @timeout

        @validated_timeout = Integer(@timeout)
      rescue ArgumentError
        @logger.warn(
          LogMessages::Authentication::AuthnK8s::InvalidTimeout.new(
            @timeout,
            DEFAULT_TIMEOUT_SEC
          )
        )
        @validated_timeout = DEFAULT_TIMEOUT_SEC
      end
    end
  end
end
