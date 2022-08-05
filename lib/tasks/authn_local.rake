# frozen_string_literal: true

namespace :authn_local do
  desc "Run the authn-local service"
  task :run, [ "socket", "queue_length", "timeout" ] => :environment do |t,args|
    socket = args["socket"] || ENV['CONJUR_AUTHN_LOCAL_SOCKET']
    queue_length = args["queue_length"] || ENV['CONJUR_AUTHN_LOCAL_QUEUE_LENGTH']
    timeout = args["timeout"] || ENV['CONJUR_AUTHN_LOCAL_TIMEOUT']

    AuthnLocal.run(socket: socket, queue_length: queue_length, timeout: timeout)
  end

  task authenticate: :environment do
    require 'json'
    require 'socket'

    response = UNIXSocket.open('/run/authn-local/.socket') do |socket|
      socket.puts({
        account: 'cucumber',
        sub: 'admin'
      }.to_json)
      JSON.parse(socket.gets)
    end
    puts("received: #{response}")
  end
end
