# frozen_string_literal: true

module Authentication
  module AuthnK8s

    class WebSocketClientEventHandler

      attr_reader :channel_closed, :message_log

      def initialize(
        ws_client:,
        stdin:,
        body:,
        pod_name:,
        validate_message:,
        message_log:,
        logger:
      )
        @ws_client = ws_client
        @stdin = stdin
        @body = body
        @pod_name = pod_name
        @validate_message = validate_message
        @message_log = message_log
        @logger = logger

        @channel_closed = false
      end

      def on_open
        handshake_error = @ws_client.handshake.error

        if handshake_error
          # Add the error to the stream instead of raising it so we continue to
          # receive other messages. At the end of this class run we will verify
          # the stream to see if any errors were written
          @ws_client.emit(
            :error,
            Errors::Authentication::AuthnK8s::WebSocketHandshakeError.new(
              handshake_error.inspect
            )
          )
          return
        end

        @logger.debug(
          LogMessages::Authentication::AuthnK8s::PodChannelOpen.new(@pod_name)
        )

        return unless @stdin

        # stdin was provided. We send it to the client.

        data = WebSocketMessage.channel_byte('stdin') + @body
        @ws_client.send(data)

        # We close the socket and don't wait for the other side to close it
        # so that we can finish handling the request quickly and don't leave the
        # Conjur server hanging. If an error occurred it will be written to
        # the client container logs.
        @ws_client.send(nil, type: :close)
      end

      def on_message(msg)
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
          @ws_client.close
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
    end
  end
end
