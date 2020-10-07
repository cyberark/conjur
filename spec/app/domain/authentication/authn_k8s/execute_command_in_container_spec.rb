# frozen_string_literal: true
require 'spec_helper'
RSpec.describe 'Authentication::AuthnK8s::ExecuteCommandInContainer' do

  class WsClientMock
    attr_accessor :received_messages, :connect_args

    def initialize(handshake_error: nil)
      @handshake_error = handshake_error

      # State saved to make on assertions on later
      @received_messages = []

      # Make the default action a no-op
      @registered_events = Hash.new { |h, k| h[k] = ->(*args) {} }
    end

    def handshake
      err = @handshake_error
      Object.new.tap do |o|
        o.define_singleton_method(:error) { err }
      end
    end

    def connect(server_url, headers:)
      @connect_args = [server_url, headers]
      # In the production class, "connect" is defined on Client::Simple, and
      # calling "connect" returns an instance of Client::Simple::Client. For
      # the mock, there's not reason to make that distinction, and we can
      # use the same object to play both roles.
      self
    end

    # "on" is used by the implementation code, not the test code.
    def on(event, &blk)
      @registered_events[event] = blk
    end

    # "send" saves received messages to assert on later.  "send" is used by
    # implementation code.  "received_messages" is used by test code.
    def send(msg, type: nil)
      @received_messages << [msg, type]
    end

    # "emit" triggers an error so that the message log includes it.
    def emit(type, *data)
      trigger_error(data)
    end

    # Methods below used only by test code
    # The "trigger_X" methods are not part of the public API we're mocking.
    # They're used only by the test code, not the implementation code.
    def trigger_open
      @registered_events[:open].call
    end

    def trigger_close
      @registered_events[:close].call
    end

    # Note: The test code will need to construct the messages it's sending
    # in the correct format.  See MessageLog code for help with that.
    def trigger_message(msg)
      @registered_events[:message].call(msg)
    end

    def trigger_error(err)
      @registered_events[:error].call(err)
    end
  end

  let(:env) do
    double('ENV').tap do |env|
      allow(env).to receive(:[])
        .with("KUBE_EXEC_COMMAND_TIMEOUT")
        .and_return(nil)
    end
  end

  let(:message) do
    double('Message').tap do |message|
      allow(message).to receive(:type).and_return(:binary)
      allow(message).to receive(:data).and_return(
        # we need to start the message with a zero byte to indicate stdin
        "#{[0].pack('c*')}some message"
      )
    end
  end

  let(:kube_client_headers) do
    double('KubeClientHeaders').tap do |kube_client_headers|
      allow(kube_client_headers).to receive(:clone)
        .and_return([])
    end
  end

  let(:kube_client_api_endpoint) do
    double('kube_client_api_endpoint').tap do |kube_client_api_endpoint|
      allow(kube_client_api_endpoint).to receive(:host)
        .and_return("host")
      allow(kube_client_api_endpoint).to receive(:port)
        .and_return("port")
    end
  end

  let(:kube_client) do
    double('KubeClient').tap do |kube_client|
      allow(kube_client).to receive(:headers)
        .and_return(kube_client_headers)
      allow(kube_client).to receive(:api_endpoint)
        .and_return(kube_client_api_endpoint)
    end
  end

  let(:k8s_object_lookup) do
    double('K8sObjectLookup').tap do |k8s_object_lookup|
      allow(k8s_object_lookup).to receive(:kube_client)
        .and_return(kube_client)
    end
  end

  let(:pod_namespace) { "PodNamespace" }
  let(:pod_name) { "PodName" }
  let(:container) { "Container" }
  let(:cmds) { %w(command1 command2) }
  let(:body) { "Body" }

  # TODO: Currently this code is repeated too many times.  With this in place,
  #   we can remove the code from everywhere else use this to create new
  #   threads.
  let(:subject_in_thread) do
    # This is ugly but needed because references to "let"-defined variables
    # inside of a closure (or at least a closure in a Thread) don't work.
    # References to ordinary local variables work fine.
    x_timeout           = timeout
    x_ws_client         = ws_client
    x_message_log_class = Authentication::AuthnK8s::MessageLog
    x_k8s_object_lookup = k8s_object_lookup
    x_pod_namespace     = pod_namespace
    x_pod_name          = pod_name
    x_container         = container
    x_cmds              = cmds
    x_body              = body

    Thread.new do
      Thread.current[:output] =
        ::Authentication::AuthnK8s::ExecuteCommandInContainer.new(
          timeout:           x_timeout,
          websocket_client:  x_ws_client,
          message_log_class: x_message_log_class,
        ).call(
          k8s_object_lookup: x_k8s_object_lookup,
          pod_namespace:     x_pod_namespace,
          pod_name:          x_pod_name,
          container:         x_container,
          cmds:              x_cmds,
          body:              x_body,
          stdin:             true
        )
    end
  end

  before(:each) do
      # Leave the output console clean from errors that occur in the thread
      Thread.report_on_exception = false
    end

    context "Calling ExecuteCommandInContainer" do

    context "when the ws_client has no handshake error" do
      context "with stdin" do
        ws_client = WsClientMock.new(handshake_error: nil)

        subject do
          # This is ugly but needed because rspec is poo, and references to
          # "let"-defined variables inside of a closure (or at least a closure
          # in a Thread) don't work.  References to ordinary local variables work
          # fine.
          x_env               = env
          x_ws_client         = ws_client
          x_message_log_class = Authentication::AuthnK8s::MessageLog
          x_k8s_object_lookup = k8s_object_lookup
          x_pod_namespace     = pod_namespace
          x_pod_name          = pod_name
          x_container         = container
          x_cmds              = cmds
          x_body              = body

          thread = Thread.new do
            Thread.current[:output] = ::Authentication::AuthnK8s::ExecuteCommandInContainer.new(
              env:               x_env,
              websocket_client:  x_ws_client,
              message_log_class: x_message_log_class,
            ).call(
              k8s_object_lookup: x_k8s_object_lookup,
              pod_namespace:     x_pod_namespace,
              pod_name:          x_pod_name,
              container:         x_container,
              cmds:              x_cmds,
              body:              x_body,
              stdin:             true
            )
          end

          # TODO: Janky way to make sure the thread has had time to setup its
          #   on_XXX listeners.  Do this with a proper sync mechanism via the mock.
          sleep 1

          ws_client.trigger_open
          ws_client.trigger_message(message)
          ws_client.trigger_close
          thread.join
          thread[:output]
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end

        it "returns the expected output" do
          expected_output = {
            :error => [],
            :stdin => ["some message"]
          }
          expect(subject).to eq(expected_output)

          # Verify also that the client received the body
          # This verification needs to be here and not in its own 'it' clause so
          # that it runs after 'subject' is called
          expect(ws_client.received_messages).to include(["#{[0].pack('c*')}#{body}", nil])
        end
      end

      context "without stdin" do
        ws_client = WsClientMock.new(handshake_error: nil)
        subject do
          # This is ugly but needed because rspec is poo, and references to
          # "let"-defined variables inside of a closure (or at least a closure
          # in a Thread) don't work.  References to ordinary local variables work
          # fine.
          x_env               = env
          x_ws_client         = ws_client
          x_message_log_class = Authentication::AuthnK8s::MessageLog
          x_k8s_object_lookup = k8s_object_lookup
          x_pod_namespace     = pod_namespace
          x_pod_name          = pod_name
          x_container         = container
          x_cmds              = cmds
          x_body              = nil

          thread = Thread.new do
            Thread.current[:output] = ::Authentication::AuthnK8s::ExecuteCommandInContainer.new(
              env:               x_env,
              websocket_client:  x_ws_client,
              message_log_class: x_message_log_class
            ).call(
              k8s_object_lookup: x_k8s_object_lookup,
              pod_namespace:     x_pod_namespace,
              pod_name:          x_pod_name,
              container:         x_container,
              cmds:              x_cmds,
              body:              x_body,
              stdin:             false
            )
          end

          # TODO: Janky way to make sure the thread has had time to setup its
          #   on_XXX listeners.  Do this with a proper sync mechanism via the mock.
          sleep 1

          ws_client.trigger_open
          ws_client.trigger_close
          thread.join
          thread[:output]
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end

        it "returns the expected output" do
          expected_output = {
            :error => []
          }
          expect(subject).to eq(expected_output)
        end
      end

      context "where the socket is not closed in time" do

        context "and KUBE_EXEC_COMMAND_TIMEOUT is not defined in the env" do
          subject do
            ws_client = WsClientMock.new(handshake_error: nil)
            # This is ugly but needed because rspec is poo, and references to
            # "let"-defined variables inside of a closure (or at least a closure
            # in a Thread) don't work.  References to ordinary local variables work
            # fine.
            x_env               = env
            x_ws_client         = ws_client
            x_message_log_class = Authentication::AuthnK8s::MessageLog
            x_k8s_object_lookup = k8s_object_lookup
            x_pod_namespace     = pod_namespace
            x_pod_name          = pod_name
            x_container         = container
            x_cmds              = cmds
            x_body              = body

            thread = Thread.new do
              Thread.current[:output] = ::Authentication::AuthnK8s::ExecuteCommandInContainer.new(
                env:               x_env,
                websocket_client:  x_ws_client,
                message_log_class: x_message_log_class
              ).call(
                k8s_object_lookup: x_k8s_object_lookup,
                pod_namespace:     x_pod_namespace,
                pod_name:          x_pod_name,
                container:         x_container,
                cmds:              x_cmds,
                body:              x_body,
                stdin:             true
              )
            end

            # TODO: Janky way to make sure the thread has had time to setup its
            #   on_XXX listeners.  Do this with a proper sync mechanism via the mock.
            sleep 1

            ws_client.trigger_open
            thread.join
            thread[:output]
          end

          it "raises an error after the default timeout" do
            expect { subject }.to raise_error(
              Errors::Authentication::AuthnK8s::ExecCommandTimedOut,
              /5 seconds/
            )
          end
        end

        context "and KUBE_EXEC_COMMAND_TIMEOUT is defined in the env" do
          ws_client = WsClientMock.new(handshake_error: nil)
          before(:each) do
            allow(env).to receive(:[])
              .with("KUBE_EXEC_COMMAND_TIMEOUT")
              .and_return("10")
          end

          subject do
            # This is ugly but needed because rspec is poo, and references to
            # "let"-defined variables inside of a closure (or at least a closure
            # in a Thread) don't work.  References to ordinary local variables work
            # fine.
            x_env               = env
            x_ws_client         = ws_client
            x_message_log_class = Authentication::AuthnK8s::MessageLog
            x_k8s_object_lookup = k8s_object_lookup
            x_pod_namespace     = pod_namespace
            x_pod_name          = pod_name
            x_container         = container
            x_cmds              = cmds
            x_body              = body

            thread = Thread.new do
              Thread.current[:output] = ::Authentication::AuthnK8s::ExecuteCommandInContainer.new(
                env:               x_env,
                websocket_client:  x_ws_client,
                message_log_class: x_message_log_class
              ).call(
                k8s_object_lookup: x_k8s_object_lookup,
                pod_namespace:     x_pod_namespace,
                pod_name:          x_pod_name,
                container:         x_container,
                cmds:              x_cmds,
                body:              x_body,
                stdin:             true
              )
            end

            # TODO: Janky way to make sure the thread has had time to setup its
            #   on_XXX listeners.  Do this with a proper sync mechanism via the mock.
            sleep 1

            ws_client.trigger_open
            thread.join
            thread[:output]
          end

          it "raises an error after the default timeout" do
            expect { subject }.to raise_error(
              Errors::Authentication::AuthnK8s::ExecCommandTimedOut,
              /10 seconds/
            )
          end
        end
      end
    end

    context "when the ws_client has a handshake error" do
      handshake_error = "handshake error"
      ws_client       = WsClientMock.new(handshake_error: handshake_error)

      subject do
        # This is ugly but needed because rspec is poo, and references to
        # "let"-defined variables inside of a closure (or at least a closure
        # in a Thread) don't work.  References to ordinary local variables work
        # fine.
        x_env               = env
        x_ws_client         = ws_client
        x_message_log_class = Authentication::AuthnK8s::MessageLog
        x_k8s_object_lookup = k8s_object_lookup
        x_pod_namespace     = pod_namespace
        x_pod_name          = pod_name
        x_container         = container
        x_cmds              = cmds
        x_body              = nil

        thread = Thread.new do
          Thread.current[:output] = ::Authentication::AuthnK8s::ExecuteCommandInContainer.new(
            env:               x_env,
            websocket_client:  x_ws_client,
            message_log_class: x_message_log_class
          ).call(
            k8s_object_lookup: x_k8s_object_lookup,
            pod_namespace:     x_pod_namespace,
            pod_name:          x_pod_name,
            container:         x_container,
            cmds:              x_cmds,
            body:              x_body,
            stdin:             false
          )
        end

        # TODO: Janky way to make sure the thread has had time to setup its
        #   on_XXX listeners.  Do this with a proper sync mechanism via the mock.
        sleep 1

        ws_client.trigger_open
        ws_client.trigger_close
        thread.join
        thread[:output]
      end

      it "raises an ExecCommandError error with the WebSocketHandshakeError" do
        expect { subject }.to raise_error(
          Errors::Authentication::AuthnK8s::ExecCommandError,
          /Errors::Authentication::AuthnK8s::WebSocketHandshakeError/
        )
      end
    end
  end
end