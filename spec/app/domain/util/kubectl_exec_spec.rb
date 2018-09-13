#require 'spec_helper'

require_relative '../../../../app/domain/util/error_class.rb'
require_relative '../../../../app/domain/util/web_socket/stream_state.rb'
require_relative '../../../../app/domain/util/web_socket/with_attributes.rb'
require_relative '../../../../app/domain/util/web_socket/with_message_saving.rb'
require_relative '../../../../app/domain/authentication/authn_k8s/kubectl_exec.rb'
require_relative '../../../support/echo_server.rb'

require 'websocket-eventmachine-server'
require 'websocket-client-simple'

RSpec.describe Authentication::AuthnK8s::KubectlExec do
  let(:api_endpoint) {
    double('dono').tap do |x|
      allow(x).to receive(:host).and_return('localhost')
      allow(x).to receive(:port).and_return('18080')
    end
  }
  
  let(:kubeclient) {
    double('KubectlClient').tap do |x|
      allow(x).to receive(:api_endpoint).and_return(api_endpoint)
      allow(x).to receive(:headers).and_return({})
    end
  }

  let(:logger) {
    double('Logger').tap do |x|
      allow(x).to receive(:debug)
    end
  }

  it "works" do
    resp = nil
    
    Thread.new do
      EM::run{ EchoServer.start }
    end

      
        resp = Authentication::AuthnK8s::KubectlExec.
          new(pod_name: "pod",
              pod_namespace: "namespace",
              logger: logger,
              kubeclient: kubeclient).
          execute(["ls"])
    
    expect(resp).to eq({})
  end

=begin
  it "times out" do
    expect {
      EM::run{
        EchoServer.start
        
        EM::add_timer 0 do
          Authentication::AuthnK8s::KubectlExec.
            new(pod_name: "pod",
                pod_namespace: "namespace",
                logger: logger,
                kubeclient: kubeclient).
            execute(["ls"])
        end
      }
    }.to raise_error(Authentication::AuthnK8s::CommandTimedOut)
  end
=end


  
=begin
  it "does a thing" do
    EM::run{
      
      EchoServer.start

      res = nil

      EM::add_timer 1 do
        WebSocket::Client::Simple.connect EchoServer.url do |client|
          client.on :open do
            client.send "hello world"
          end

          client.on :message do |msg|
            res = msg.to_s
          end
        end
      end

      EM::add_timer 2 do
        expect(res).to eq("hello world")
        EM::stop_event_loop
      end
    }
  end
=end
end
