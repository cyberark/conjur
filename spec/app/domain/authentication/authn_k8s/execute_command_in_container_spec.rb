# frozen_string_literal: true

require 'spec_helper'
RSpec.describe('Authentication::AuthnK8s::ExecuteCommandInContainer') do
  class WsClientMock
    attr_accessor :received_messages, :connect_args, :ready_listeners_queue

    def initialize(handshake_error: nil)
      @handshake_error = handshake_error

      # We need to wait until all the listeners (on_xxx methods) are ready before
      # running the UT so that we don't have a race condition.
      @ready_listeners_queue = Queue.new

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

    def connect(server_url, options)
      @connect_args = [server_url, options]
      # In the production class, "connect" is defined on Client::Simple, and
      # calling "connect" returns an instance of Client::Simple::Client. For
      # the mock, there's not reason to make that distinction, and we can
      # use the same object to play both roles.
      self
    end

    # "on" is used by the implementation code, not the test code.
    def on(event, &blk)
      @registered_events[event] = blk

      # The value itself doesn't matter, so we just use nil
      @ready_listeners_queue << nil
    end

    # "send" saves received messages to assert on later.  "send" is used by
    # implementation code.  "received_messages" is used by test code.
    def send(msg, type: nil)
      @received_messages << [msg, type]
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

    # NOTE: The test code will need to construct the messages it's sending
    # in the correct format.  See MessageLog code for help with that.
    def trigger_message(msg)
      @registered_events[:message].call(msg)
    end

    def trigger_error(err)
      @registered_events[:error].call(err)
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
    URI.parse("https://path/to/api/endpoint")
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
      allow(k8s_object_lookup).to receive(:cert_store)
        .and_return("cert_store")
    end
  end

  let(:pod_namespace) { "PodNamespace" }
  let(:pod_name) { "PodName" }
  let(:container) { "Container" }
  let(:cmds) { %w[command1 command2] }
  let(:body) { "Body" }

  # This is used in test code to verify that all the client listeners are ready.
  # We wait for this timeout while verifying this
  let(:ready_listeners_timeout) { 5 }

  def subject_in_thread(ws_client:, timeout:, body:, stdin:)
    # This is ugly but needed because references to "let"-defined variables
    # inside of a closure (or at least a closure in a Thread) don't work.
    # References to ordinary local variables work fine.
    x_timeout           = timeout
    x_ws_client         = ws_client
    x_k8s_object_lookup = k8s_object_lookup
    x_pod_namespace     = pod_namespace
    x_pod_name          = pod_name
    x_container         = container
    x_cmds              = cmds
    x_body              = body
    x_stdin             = stdin

    Thread.new do
      Thread.current[:output] =
        ::Authentication::AuthnK8s::ExecuteCommandInContainer.new(
          timeout: x_timeout,
          websocket_client: x_ws_client
        ).call(
          k8s_object_lookup: x_k8s_object_lookup,
          pod_namespace: x_pod_namespace,
          pod_name: x_pod_name,
          container: x_container,
          cmds: x_cmds,
          body: x_body,
          stdin: x_stdin
        )
    end.tap do
      # Verify all 4 listeners are ready before resuming the UT
      Timeout.timeout(ready_listeners_timeout) do
        4.times do
          ws_client.ready_listeners_queue.pop
        end
      end
    end
  end

  before(:each) do
    # Leave the output console clean from errors that occur in the thread
    Thread.report_on_exception = false
  end

  context "Calling ExecuteCommandInContainer" do
    context "converts endpoint for websocket client" do
      let(:kube_client_api_endpoint) do
        raise "@kube_client_api_endpoint not defined" unless @kube_client_api_endpoint

        URI.parse(@kube_client_api_endpoint)
      end

      let(:ws_client) do 
        ws_client = WsClientMock.new(handshake_error: nil)
        
        thread = subject_in_thread(
          ws_client: ws_client,
          timeout: 1,
          body: body,
          stdin: true
        )

        ws_client.trigger_open
        ws_client.trigger_message(message)
        ws_client.trigger_close
        thread.join
        thread[:output]

        ws_client
      end

      it "retains subpath" do
        @kube_client_api_endpoint = "https://path/to"

        expect(ws_client.connect_args[0]).to eq(
          "wss://path/to/v1/namespaces/PodNamespace/pods/PodName/exec?container=Container&stderr=true&stdout=true&stdin=true&command=command1&command=command2"
        )
      end

      it "retains port" do
        @kube_client_api_endpoint = "https://path/to:5432"

        expect(ws_client.connect_args[0]).to eq(
          "wss://path/to:5432/v1/namespaces/PodNamespace/pods/PodName/exec?container=Container&stderr=true&stdout=true&stdin=true&command=command1&command=command2"
        )
      end

      it "retains query params" do
        @kube_client_api_endpoint = "https://path/to?meow=moo"

        expect(ws_client.connect_args[0]).to eq(
          "wss://path/to/v1/namespaces/PodNamespace/pods/PodName/exec?meow=moo&container=Container&stderr=true&stdout=true&stdin=true&command=command1&command=command2"
        )
      end

      it "retains everything" do
        @kube_client_api_endpoint = "https://path/to:5342?meow=moo"

        expect(ws_client.connect_args[0]).to eq(
          "wss://path/to:5342/v1/namespaces/PodNamespace/pods/PodName/exec?meow=moo&container=Container&stderr=true&stdout=true&stdin=true&command=command1&command=command2"
        )
      end
    end

    context "when the ws_client has no handshake error" do
      context "with stdin" do
        ws_client = WsClientMock.new(handshake_error: nil)
        subject do
          thread = subject_in_thread(
            ws_client: ws_client,
            timeout: 10,
            body: body,
            stdin: true
          )

          ws_client.trigger_open
          ws_client.trigger_message(message)
          ws_client.trigger_close
          thread.join
          thread[:output]
        end

        it "returns the expected output" do
          expected_output = {
            error: [],
            stdin: ["some message"]
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
          thread = subject_in_thread(
            ws_client: ws_client,
            timeout: 10,
            body: body,
            stdin: false
          )

          ws_client.trigger_open
          ws_client.trigger_close
          thread.join
          thread[:output]
        end

        it "returns the expected output" do
          expected_output = {
            error: []
          }
          expect(subject).to eq(expected_output)
        end
      end

      context "where the socket is not closed in time" do
        context "and KUBE_EXEC_COMMAND_TIMEOUT is not defined in the env" do
          ws_client = WsClientMock.new(handshake_error: nil)
          subject do
            thread = subject_in_thread(
              ws_client: ws_client,
              timeout: nil,
              body: body,
              stdin: true
            )

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
          context "with an integer" do
            ws_client = WsClientMock.new(handshake_error: nil)
            subject do
              thread = subject_in_thread(
                ws_client: ws_client,
                timeout: 10,
                body: body,
                stdin: true
              )

              ws_client.trigger_open
              thread.join
              thread[:output]
            end

            it "raises an error after the given timeout" do
              expect { subject }.to raise_error(
                Errors::Authentication::AuthnK8s::ExecCommandTimedOut,
                /10 seconds/
              )
            end
          end

          context "with a value that is not an integer" do
            ws_client = WsClientMock.new(handshake_error: nil)
            subject do
              thread = subject_in_thread(
                ws_client: ws_client,
                timeout: "not-an-int",
                body: body,
                stdin: true
              )

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
        end
      end
    end

    context "when the ws_client has a handshake error" do
      handshake_error = "handshake error"
      ws_client       = WsClientMock.new(handshake_error: handshake_error)
      subject do
        thread = subject_in_thread(
          ws_client: ws_client,
          timeout: 10,
          body: nil,
          stdin: false
        )

        ws_client.trigger_open
        ws_client.trigger_close
        thread.join
        thread[:output]
      end

      it "raises a WebSocketHandshakeError error" do
        expect { subject }.to raise_error(
          Errors::Authentication::AuthnK8s::WebSocketHandshakeError
        )
      end
    end
  end
end
