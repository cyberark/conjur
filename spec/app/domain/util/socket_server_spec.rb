# frozen_string_literal: true

require 'spec_helper'

describe Util::SocketService do

  let(:service)  do
    Util::SocketService.new(
      socket: socket
    )
  end

  describe('#run') do
    context 'When a socket is started' do
      context 'When the socket file already exists' do
        let(:socket) {'/run/authn-local/.socket'}
        it 'raises an error' do
          expect do
            service.run do |passed_arguments|
              Authentication::AuthnOidc::V2::Commands::ListProviders.new.call(
                message: passed_arguments
              )
            end
          end.to raise_error("Socket: /run/authn-local/.socket already exists")
        end
      end

      context 'When the socket directory can not be found' do
        let(:socket) {'/run/test/.socket'}
        it 'raises an error' do
          expect do
            service.run do |passed_arguments|
              Authentication::AuthnOidc::V2::Commands::ListProviders.new.call(
                message: passed_arguments
              )
            end
          end.to raise_error('Socket Service requires directory "/run/test" to exist and be a directory')
        end
      end

      context 'When the socket is given a code block' do
        let(:socket) {'/run/authn-local/.socket100'}
        it 'will handle the input with the code block' do
          thread = Thread.new do
            service.run do |passed_arguments|
               passed_arguments
            end
          end
          # Allow the socket server time to start
          sleep(2)
          res = UNIXSocket.open(socket) do |socket|
            socket.puts({ account: "cucumber" }.to_json)
            JSON.parse(socket.gets)
          end
          thread.exit
          expect(res).to eq("{\"account\":\"cucumber\"}")
        end
      end
    end
  end
end