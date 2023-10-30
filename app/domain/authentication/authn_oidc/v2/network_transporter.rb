# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class NetworkTransporter
        def initialize(hostname:, ca_certificate: nil, temp_directory: './tmp/certificates', http: Net::HTTP)
          # Set as empty so we can check it later when making network calls
          @ca_certificate = nil
          if ca_certificate.present?
            @temp_directory = temp_directory
            create_directory_if_missing(temp_directory)
            @ca_certificate = ca_certificate
          end

          # Set the default hostname
          @uri = URI(hostname)
          # Stripping path if present
          @uri.path = ''

          @http = http

          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        def get(path)
          http_client.start do |http|
            request = Net::HTTP::Get.new(@uri.to_s + URI(path).path)
            response = http.request(request)
            if response.code == '200'
              @success.new(JSON.parse(response.body))
            else
              @failure.new(response)
            end
          end
        rescue => e
          @failure.new(e.message, exception: e, status: :bad_request)
        end

        def post(path:, body: '', basic_auth: [])
          http_client.start do |http|
            request = Net::HTTP::Post.new(@uri + URI(path).path)
            request.body = body
            request.basic_auth(*basic_auth) unless basic_auth.empty?
            response = http.request(request)
            begin
              if response.code == '200'
                @success.new(JSON.parse(response.body))
              else
                @failure.new(response)
              end
            rescue => e
              @failure.new(e.message, exception: e, status: :bad_request)
            end
          end
        end

        private

        def http_client
          @http_client ||= begin
            http = @http.new(@uri.host, @uri.port)
            return http unless @uri.instance_of?(URI::HTTPS)

            # Enable SSL support
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER

            store = OpenSSL::X509::Store.new
            # If CA Certificate is available, we write it to a tempfile for
            # import. This allows us to handle certificate chains.
            if @ca_certificate.present?
              with_ca_certificate(@ca_certificate) do |file|
                store.add_file(file.path)
              end
            else
              # Auto-include system CAs unless a CA has been defined
              store.set_default_paths
            end
            http.cert_store = store

            # return the http object
            http
          end
        end

        def with_ca_certificate(certificate_content, &block)
          Tempfile.create('ca', @temp_directory) do |ca_certificate|
            ca_certificate.write(certificate_content)
            ca_certificate.close
            block.call(ca_certificate)
          end
        end

        def create_directory_if_missing(path)
          Dir.mkdir(path) unless Dir.exist?(path)
        end
      end
    end
  end
end
