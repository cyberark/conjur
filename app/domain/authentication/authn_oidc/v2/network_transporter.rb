# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class NetworkTransporter
        def initialize(authenticator:)
          @authenticator = authenticator

          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        def get(url)
          # make_call do |client|
          #   client.post(url, body, headers).body
          # end
          with_ssl do |ssl_options|
            network_call(ssl_options) do |client|
              client.get(url).body
            end
          end
        end

        def post(url:, body:, headers: {})
          with_ssl do |ssl_options|
            network_call(ssl_options) do |client|
              @success.new(client.post(url, body, headers).body)
            end
          end
        rescue => e
          @failure.new(e.message, exception: e, status: :bad_request)
        end

        private

        def make_call(&block)
          with_ssl do |ssl_options|
            network_call(ssl_options) do |client|
              block.call(client)
              # client.post(url, body, headers).body
            end
          end
        end

        def with_ca(ssl_options, &block)
          Dir.mkdir('./tmp/certificates') unless Dir.exist?('./tmp/certificates')
          Tempfile.create('ca', './tmp/certificates/') do |ca_certificate|
            ca_certificate.write(@authenticator.ca_cert)
            ca_certificate.flush
            ssl_options[:ca_file] = ca_certificate.path

            block.call(ssl_options)

          ensure
            File.delete(ca_certificate.path) if File.exist?(ca_certificate.path)
          end
        end

        def with_ssl(&block)
          ssl_options = {}
          if @authenticator.ca_cert.present?
            with_ca(ssl_options) do |updated_ssl_options|
              block.call(updated_ssl_options)
            end
          else
            block.call(ssl_options)
          end
        end

        def network_call(ssl_options, &block)
          client = Faraday.new(@authenticator.provider_uri, ssl: ssl_options) do |conn|
            conn.response(:json, content_type: /\bjson$/)
            conn.response(:raise_error)

            conn.adapter(Faraday.default_adapter)
          end

          block.call(client)
        end
      end
    end
  end
end
