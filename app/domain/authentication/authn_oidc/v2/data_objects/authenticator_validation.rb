module Authentication
  module AuthnOidc
    module V2
      module DataObjects
        class AuthenticatorContract < Dry::Validation::Contract
          params do
            required(:provider_uri).filled(:string)
            required(:client_id).filled(:string)
            required(:client_secret).filled(:string)
            required(:account).filled(:string)
            required(:service_id).filled(:string)
          end

          rule(:provider_uri) do
            unless value =~ URI::regexp
              key.failure('has invalid format. It must be a valid URI')
            end
            begin
              url = URI.parse("#{value}/.well-known/openid-configuration")
              request = Net::HTTP.new(url.host, url.port)
              request.use_ssl = true if url.scheme == 'https'
              response = request.request_head(url.path)

              key.failure('is not available') if response.code != '200'
            rescue SocketError => e
              key.failure("is not reachable: #{e}")
            end
          end
        end
      end
    end
  end
end
