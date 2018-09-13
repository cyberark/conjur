module EchoServer
  def self.start
    WebSocket::EventMachine::Server.start(:host => "0.0.0.0", :port => self.port) do |ws|
      # @channel = EM::Channel.new
      ws.onopen do
        # sid = @channel.subscribe do |mes|
          ws.send "hello"  # echo to client
        # end
        ws.onmessage do |msg|
          puts "Echoing... #{msg}"
          @channel.push msg
        end
        ws.onclose do
          @channel.unsubscribe sid
        end
      end
    end
  end

  def self.port
    (ENV['WS_PORT'] || 18080).to_i
  end

  def self.url
    "ws://localhost:#{self.port}"
  end
end
