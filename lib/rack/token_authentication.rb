# frozen_string_literal: true

require 'jwt'

module Rack
  class TokenAuthentication

    class AuthorizationError < SecurityError
    end

    class SignatureError < SecurityError
    end

    class Forbidden < SecurityError
    end

    AuthTokenDetails = Struct.new(:role_id, :claims, :request_ip, keyword_init: true) do
      def account
        role_id.split(':').first
      end
    end

    # +options+:
    # :except :: a list of request path patterns for which to skip authentication.
    # :optional :: request path patterns for which authentication is optional.
    def initialize(app, options, slosilo: Slosilo)
      @app = app
      @options = options
      @slosilo = slosilo
    end

    def call(env)
      # Duplicate for thread safety
      dup._call(env)
    end

    def _call(env)
      request_path = [ env['SCRIPT_NAME'], env['PATH_INFO'] ].join

      if authentication_required?(request_path)
        begin
          request_ip = ::Rack::Request.new(env).ip
          raw_token = env['HTTP_AUTHORIZATION'].to_s[/^Token token="(.*)"/, 1]

          if raw_token.present?
            claims = validate_authentication_token(raw_token)

            unless ip_address_permissible?(claims: claims, ip_address: request_ip)
              raise(Forbidden, 'IP address rejected')
            end

            env['conjur-token-authentication.token_details'] = AuthTokenDetails.new(
              role_id: claims['sub'],
              claims: claims.slice('sub', 'iat', 'exp'),
              request_ip: request_ip
            )
          else
            unless authentication_optional?(request_path)
              raise(AuthorizationError, 'Authorization missing')
            end
          end

        rescue Forbidden => e
          return error_response(status: 403, message: e.message)
        rescue SecurityError => e
          return error_response(status: 401, message: e.message)
        end
      end

      # call the next rack application
      @app.call(env)
    end

    protected

    def get_slosilo_key_by_fingerprint(fingerprint)
      @slosilo.each do |id, key|
        return id, key if key.fingerprint == fingerprint
      end

      raise(SignatureError, 'Valid signing key not found')
    end

    def validate_authentication_token(token)
      # If the auth token comes in Base64 encoded, decode it.
      # Note: The decoded string includes double quotes which need to be removed.
      token = Base64.decode64(token).tr('""', '') unless token.include?('.')

      fingerprint = JSON.parse(Base64.decode64(token.split('.').first))['x5t']
      key_id, signing_key = get_slosilo_key_by_fingerprint(fingerprint)

      unless key_id.match?(/\Aauthn:(\w+):?\z/)
        raise(SignatureError, 'Invalid signing key identifier')
      end

      begin
        claims, = JWT.decode(
          token,
          signing_key.key.public_key,
          true,
          {
            algorithm: 'RS256',
            iss: 'cyberark/conjur',
            verify_iss: true,
            verify_iat: true
          }
        )
      rescue JWT::DecodeError => e
        raise(SignatureError, "Token verification failed: '#{e.message}'")
      end
      claims
    end

    def ip_address_permissible?(ip_address:, claims:)
      return true unless claims.key?('restricted_to')

      claims['restricted_to']
        .map(&IPAddr.method(:new))
        .any? { |c| c.include?(ip_address) }
    end

    def authentication_required?(path)
      [*@options[:except]].find{ |p| p.match(path) }.nil?
    end

    def authentication_optional?(path)
      [*@options[:optional]].find { |p| p.match(path) }
    end

    def error_response(status:, message:)
      [status, { 'Content-Type' => 'text/plain', 'Content-Length' => message.length.to_s }, [message] ]
    end
  end
end
