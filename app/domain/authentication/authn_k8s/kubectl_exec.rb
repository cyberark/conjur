require 'websocket'
require 'kubectl_client'
require 'rubygems/package'

module Authentication
  module AuthnK8s
    class KubectlExec
      STDIN_CHANNEL = 0
      STDOUT_CHANNEL = 1
      STDERR_CHANNEL = 2
      ERROR_CHANNEL = 3
      RESIZE_CHANNEL = 4

      attr_reader :pod, :container, :timeout, :ws

      def initialize pod, container: "authentication", timeout: 5.seconds
        @pod = pod
        @container = container
        @timeout = timeout
      end

      def exec command, body: "", stdin: false
        kubectl = K8sObjectLookup.kubectl_client

        base_url = "wss://#{kubectl.api_endpoint.host}:#{kubectl.api_endpoint.port}"
        path = "/api/v1/namespaces/#{pod.metadata.namespace}/pods/#{pod.metadata.name}/exec"

        query = [
          "container=#{CGI.escape container}",
          "stderr=true",
          "stdout=true",
        ]
        query << "stdin=true" if stdin

        for arg in Array(command)
          query << "command=#{CGI.escape arg}"
        end
        query = query.join("&")

        url = "#{base_url}#{path}?#{query}"
        headers = kubectl.headers.clone

        ws = @ws = WebSocket::Client::Simple.connect url, headers: headers
        ws.instance_variable_set "@messages", Hash.new {|hash,key| hash[key] = []}
        ws.instance_variable_set "@pod", pod
        ws.instance_variable_set "@closed", false

        class << ws
          def message_binary msg
            channel = msg.data[0..0].bytes.first
            stream = case channel
                     when STDOUT_CHANNEL
                       "stdout"
                     when STDERR_CHANNEL
                       "stderr"
                     when ERROR_CHANNEL
                       "error"
                     when RESIZE_CHANNEL
                       "resize"
                     else
                       raise "Unexpected channel number : #{channel}"
                     end
            @messages[stream.to_sym] << msg.data[1..-1]
            Rails.logger.debug "Pod #{@pod.metadata.name.inspect} message :#{stream} : #{msg.data[1..-1]}"
          end

          def message_close msg
            Rails.logger.debug "Pod #{@pod.metadata.name.inspect} message :#{close} : #{msg.data[1..-1]}"
            close
          end
        end

        ws.on :message do |msg|
          __send__ "message_#{msg.type}", msg
        end

        ws.on :open do
          hs = ws.handshake
          if hs.error
            emit :error, hs.instance_variable_get("@data")
          else
            Rails.logger.debug "Pod #{@pod.metadata.name.inspect} : channel open"

            if stdin
              ws.send(STDIN_CHANNEL.chr + body)
              ws.send nil, :type => :close
            end
          end
        end

        ws.on :close do |e|
          @closed = true
          Rails.logger.debug "Pod #{@pod.metadata.name.inspect} : channel closed"
        end

        ws.on :error do |e|
          @closed = true
          Rails.logger.debug "Pod #{@pod.metadata.name.inspect} error : #{e.inspect}"
          @messages[:error] << e.inspect
        end

        ws.send "\n"

        (@timeout / 0.1).to_i.times do
          break if ws.instance_variable_get("@closed")
          sleep 0.1
        end

        if ws.instance_variable_get("@closed")
          ws.instance_variable_get "@messages"
        else
          raise "Command timed out in container #{container.inspect} of Pod #{@pod.metadata.name.inspect}"
        end
      end

      def copy path, content, mode
        exec [ 'tar', 'xvf', '-', '-C', '/' ], stdin: true, body: generate_file_tar_string(path, content, mode)
      end

      private

      def generate_file_tar_string path, content, mode
        tarfile = StringIO.new("")
        Gem::Package::TarWriter.new(tarfile) do |tar|
          tar.add_file path, mode do |tf|
            tf.write content
          end
        end

        tarfile.string
      end
    end
  end
end
