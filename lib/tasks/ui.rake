# frozen_string_literal: true

require './app/domain/util/socket_server'
require './app/domain/authentication/authn_oidc/v2/commands/list_providers'

namespace :ui do
  task run: :environment do
    logger = Logger.new($stderr, level: Logger::DEBUG)
    Util::SocketService.new(
      socket: '/run/ui/.socket',
      logger: logger
    ).run do |passed_arguments|
      Authentication::AuthnOidc::V2::Commands::ListProviders.new(
        logger: logger
      ).call(
        message: passed_arguments
      )
    end
  end

  task retrieve_providers: :environment do
    require 'json'
    require 'socket'

    response = UNIXSocket.open('/run/ui/.socket') do |socket|
      socket.puts({ account: 'cucumber' }.to_json)
      JSON.parse(socket.gets)
    end
    puts("received: #{response}")
  end
end
