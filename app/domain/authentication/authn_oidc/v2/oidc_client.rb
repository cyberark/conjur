# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class OidcClient
        def initialize(
          authenticator:,
          client: NetworkTransporter,
          cache: Rails.cache,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @cache = cache
          @logger = logger

          @client = client.new(
            authenticator: authenticator
          )

          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        def exchange(code:, nonce:, code_verifier: nil)
          exchange_token(code: code, nonce: nonce, code_verifier: code_verifier).bind do |bearer_token|
            decode_token(bearer_token).bind do |decoded_token|
              verify_token(token: decoded_token, nonce: nonce).bind do |verified_token|
                @success.new(verified_token)
              end
            end
          end
        end

        # 'jwks_uri' - GET
        # 'token_endpoint' - POST
        # Public method so strategy can call it to verify configuration
        def configuration
          @configuration ||= @client.get('.well-known/openid-configuration')
        end

        private

        def exchange_token(code:, nonce:, code_verifier:)
          args = {
            grant_type: 'authorization_code',
            scope: true,
            code: code,
            nonce: nonce
          }
          args[:code_verifier] = code_verifier if code_verifier.present?
          args[:redirect_uri] = ERB::Util.url_encode(@authenticator.redirect_uri) if @authenticator.redirect_uri.present?

          # begin
            # binding.pry
            response = @client.post(
              url: configuration['token_endpoint'].gsub("#{@authenticator.provider_uri}/", ''),
              body: args.map { |k, v| "#{k}=#{v}" }.join('&'),
              headers: { 'Authorization' => "Basic #{Base64.strict_encode64([@authenticator.client_id, @authenticator.client_secret].join(':'))}" }
            ).bind do |response|
              return @success.new(response['id_token'] || response['access_token'])
            end
          # rescue => e
            # binding.pry
            @failure.new(
              response.message,
              exception: Errors::Authentication::AuthnOidc::TokenRetrievalFailed.new(e.message),
              status: :unauthorized
            )
          # end
            # binding.pry
        end

        def decode_token(encoded_token)
          @success.new(
            JWT.decode(
              encoded_token,
              nil,
              true, # Verify the signature of this token
              algorithms: %w[RS256 RS384 RS512],
              iss: @authenticator.provider_uri,
              verify_iss: true,
              aud: @authenticator.client_id,
              verify_aud: true,
              jwks: fetch_jwks
            ).first
          )
        rescue => e
          @failure.new(e.message, exception: e, status: :bad_request)
        end

        def verify_token(token:, nonce:)
          unless token['nonce'] == nonce
            return @failure.new('nonce does not match')
          end

          @success.new(token)
        end

        def fetch_jwks
          @client.get(
            configuration['jwks_uri'].gsub("#{@authenticator.provider_uri}/", '')
          )
        end

        # def exchange_code_for_token(code:, nonce:, code_verifier: nil)
        #   args = {
        #     grant_type: 'authorization_code',
        #     scope: true,
        #     code: code,
        #     nonce: nonce
        #   }
        #   args[:code_verifier] = code_verifier if code_verifier.present?
        #   args[:redirect_uri] = ERB::Util.url_encode(@authenticator.redirect_uri) if @authenticator.redirect_uri.present?

        #   response = @client.post(
        #     url: configuration['token_endpoint'].gsub("#{@authenticator.provider_uri}/", ''),
        #     body: args.map { |k, v| "#{k}=#{v}" }.join('&'),
        #     headers: { 'Authorization' => "Basic #{Base64.strict_encode64([@authenticator.client_id, @authenticator.client_secret].join(':'))}" }
        #   )

        #   bearer_token = response['id_token'] || response['access_token']

        #   decoded_jwt = JWT.decode(
        #     bearer_token,
        #     nil,
        #     true, # Verify the signature of this token
        #     algorithms: %w[RS256 RS384 RS512],
        #     iss: @authenticator.provider_uri,
        #     verify_iss: true,
        #     aud: @authenticator.client_id,
        #     verify_aud: true,
        #     jwks: fetch_jwks
        #   ).first

        #   unless decoded_jwt['nonce'] == nonce
        #     return @failure.new('nonce does not match')
        #   end

        #   @success.new(decoded_jwt)
        # end


        # # Writing certificates to the default system cert store requires
        # # superuser privilege. Instead, Conjur will use ${CONJUR_ROOT}/tmp/certs.
        # def self.default_cert_dir(dir: Dir, fileutils: FileUtils)
        #   if @default_cert_dir.blank?
        #     conjur_root = __dir__.slice(0..(__dir__.index('/app')))
        #     @default_cert_dir = File.join(conjur_root, "tmp/certs")
        #   end

        #   fileutils.mkdir_p(@default_cert_dir) unless dir.exist?(@default_cert_dir.to_s)

        #   @default_cert_dir
        # end

        # def oidc_client
        #   @oidc_client ||= begin
        #     issuer_uri = URI(@authenticator.provider_uri)
        #     @client.new(
        #       identifier: @authenticator.client_id,
        #       secret: @authenticator.client_secret,
        #       redirect_uri: @authenticator.redirect_uri,
        #       scheme: issuer_uri.scheme,
        #       host: issuer_uri.host,
        #       port: issuer_uri.port,
        #       authorization_endpoint: URI(discovery_information.authorization_endpoint).path,
        #       token_endpoint: URI(discovery_information.token_endpoint).path,
        #       userinfo_endpoint: URI(discovery_information.userinfo_endpoint).path,
        #       jwks_uri: URI(discovery_information.jwks_uri).path
        #     )
        #   end
        # end

        # def callback(code:, nonce:, code_verifier: nil)
        #   response = exchange_code_for_token(code: code, nonce: nonce, code_verifier: code_verifier)
        #   # binding.pry

        #   # oidc_client.authorization_code = code
        #   # access_token_args = { client_auth_method: :basic }
        #   # access_token_args[:code_verifier] = code_verifier if code_verifier.present?
        #   # begin
        #   #   bearer_token = oidc_client.access_token!(**access_token_args)
        #   # rescue Rack::OAuth2::Client::Error => e
        #   #   return @failure.new(
        #   #     e.message,
        #   #     exception: Errors::Authentication::AuthnOidc::TokenRetrievalFailed.new(e.message),
        #   #     status: :bad_request
        #   #   )
        #   # end
        #   # id_token = bearer_token.id_token || bearer_token.access_token

        #   # begin
        #   #   attempts ||= 0
        #   #   decoded_id_token = @oidc_id_token.decode(
        #   #     id_token,
        #   #     discovery_information.jwks
        #   #   )

        #   # rescue => e
        #   #   attempts += 1
        #   #   if attempts > 1
        #   #     return @failure.new(
        #   #       'JWKS signing check failed',
        #   #       exception: e,
        #   #       status: :unauthorized
        #   #     )
        #   #   end
        #   #   # If the JWKS verification fails, blow away the existing cache and
        #   #   # try again. This is intended to handle the case where the OIDC certificate
        #   #   # changes, and we want to cache the new certificate without decode failing.
        #   #   discovery_information(invalidate: true)
        #   #   retry
        #   # end

        #   # begin
        #   #   decoded_id_token.verify!(
        #   #     issuer: @authenticator.provider_uri,
        #   #     client_id: @authenticator.client_id,
        #   #     nonce: nonce
        #   #   )
        #   #   @success.new(decoded_id_token)
        #   # rescue => e
        #   #   @failure.new(
        #   #     e.message,
        #   #     exception: e,
        #   #     status: :bad_request
        #   #   )
        #   # end
        # end

        # # callback_with_temporary_cert wraps the callback method with commands
        # # to write & clean up a given certificate or cert chain in a given
        # # directory. By default, ${CONJUR_ROOT}/tmp/certs is used.
        # #
        # # The temporary certificate file name is "x.n", where x is the hash of
        # # the certificate subject name, and n is incrememnted from 0 in case of
        # # collision.
        # #
        # # Unlike self.discover, which wraps a single ::OpenIDConnect method,
        # # callback_with_temporary_cert wraps the entire callback method, which
        # # includes multiple calls to the OIDC provider, including at least one
        # # discover! call. The temporary certs will apply to all required
        # # operations.
        # def callback_with_temporary_cert(
        #   code:,
        #   nonce:,
        #   code_verifier: nil,
        #   cert_dir: Authentication::AuthnOidc::V2::Client.default_cert_dir,
        #   cert_string: nil
        # )
        #   c = -> { callback(code: code, nonce: nonce, code_verifier: code_verifier) }

        #   return c.call if cert_string.blank?

        #   begin
        #     certs_a = ::Conjur::CertUtils.parse_certs(cert_string)
        #   rescue OpenSSL::X509::CertificateError => e
        #     raise Errors::Authentication::AuthnOidc::InvalidCertificate, e.message
        #   end
        #   raise Errors::Authentication::AuthnOidc::InvalidCertificate, "provided string does not contain a certificate" if certs_a.empty?

        #   symlink_a = []

        #   Dir.mktmpdir do |tmp_dir|
        #     certs_a.each_with_index do |cert, idx|
        #       tmp_file = File.join(tmp_dir, "conjur-oidc-client.#{idx}.pem")
        #       File.write(tmp_file, cert.to_s)

        #       n = 0
        #       hash = cert.subject.hash.to_s(16)
        #       while true
        #         symlink = File.join(cert_dir, "#{hash}.#{n}")
        #         break unless File.exist?(symlink)

        #         n += 1
        #       end

        #       File.symlink(tmp_file, symlink)
        #       symlink_a << symlink
        #     end

        #     if OpenIDConnect.http_config.nil? || OpenIDConnect.http_client.ssl.ca_path != cert_dir
        #       config_proc = proc do |config|
        #         config.ssl.ca_path = cert_dir
        #         config.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER
        #       end

        #       # OpenIDConnect gem only accepts a single Faraday configuration
        #       # through calls to its .http_config method, and future calls to
        #       # the #http_config method return the first config instance.
        #       #
        #       # On the first call to OpenIDConnect.http_config, it will pass the
        #       # new Faraday configuration to its dependency gems that also have
        #       # nil configs. We can't be certain that each gem is configured
        #       # with the same Faraday config and need them synchronized, so we
        #       # inject them manually.
        #       OpenIDConnect.class_variable_set(:@@http_config, config_proc)
        #       WebFinger.instance_variable_set(:@http_config, config_proc)
        #       SWD.class_variable_set(:@@http_config, config_proc)
        #       Rack::OAuth2.class_variable_set(:@@http_config, config_proc)
        #     end

        #     c.call
        #   ensure
        #     symlink_a.each{ |s| File.unlink(s) if s.present? && File.symlink?(s) }
        #   end
        # end

        # def discovery_information(invalidate: false)
        #   @cache.fetch(
        #     "#{@authenticator.account}/#{@authenticator.service_id}/#{URI::Parser.new.escape(@authenticator.provider_uri)}",
        #     force: invalidate,
        #     skip_nil: true
        #   ) do
        #     self.class.discover(
        #       provider_uri: @authenticator.provider_uri,
        #       discovery_configuration: @discovery_configuration,
        #       cert_string: @authenticator.ca_cert
        #     )
        #   rescue Errno::ETIMEDOUT => e
        #     raise Errors::Authentication::OAuth::ProviderDiscoveryTimeout.new(@authenticator.provider_uri, e.message)
        #   rescue => e
        #     raise Errors::Authentication::OAuth::ProviderDiscoveryFailed.new(@authenticator.provider_uri, e.message)
        #   end
        # end

        # # discover wraps ::OpenIDConnect::Discovery::Provider::Config.discover!
        # # with commands to write & clean up a given certificate or cert chain in
        # # a given directory. By default, ${CONJUR_ROOT}/tmp/certs is used.
        # #
        # # The temporary certificate file name is "x.n", where x is the hash of
        # # the certificate subject name, and n is incremented from 0 in case of
        # # collision.
        # #
        # # discover is a class method, because there are a few contexts outside
        # # this class where the underlying discover! method is used. Call it by
        # # running Authentication::AuthnOIDC::V2::Client.discover(...).
        # def self.discover(
        #   provider_uri:,
        #   discovery_configuration: ::OpenIDConnect::Discovery::Provider::Config,
        #   cert_dir: default_cert_dir,
        #   cert_string: nil,
        #   jwks: false
        # )
        #   case jwks
        #   when false
        #     d = -> { discovery_configuration.discover!(provider_uri) }
        #   when true
        #     d = -> { discovery_configuration.discover!(provider_uri).jwks }
        #   end

        #   return d.call if cert_string.blank?

        #   begin
        #     certs_a = ::Conjur::CertUtils.parse_certs(cert_string)
        #   rescue OpenSSL::X509::CertificateError => e
        #     raise Errors::Authentication::AuthnOidc::InvalidCertificate, e.message
        #   end
        #   raise Errors::Authentication::AuthnOidc::InvalidCertificate, "provided string does not contain a certificate" if certs_a.empty?

        #   symlink_a = []

        #   Dir.mktmpdir do |tmp_dir|
        #     certs_a.each_with_index do |cert, idx|
        #       tmp_file = File.join(tmp_dir, "conjur-oidc-client.#{idx}.pem")
        #       File.write(tmp_file, cert.to_s)

        #       n = 0
        #       hash = cert.subject.hash.to_s(16)
        #       while true
        #         symlink = File.join(cert_dir, "#{hash}.#{n}")
        #         break unless File.exist?(symlink)

        #         n += 1
        #       end

        #       File.symlink(tmp_file, symlink)
        #       symlink_a << symlink
        #     end

        #     if OpenIDConnect.http_config.nil? || OpenIDConnect.http_client.ssl.ca_path != cert_dir
        #       config_proc = proc do |config|
        #         config.ssl.ca_path = cert_dir
        #         config.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER
        #       end

        #       # OpenIDConnect gem only accepts a single Faraday configuration
        #       # through calls to its .http_config method, and future calls to
        #       # the #http_config method return the first config instance.
        #       #
        #       # On the first call to OpenIDConnect.http_config, it will pass the
        #       # new Faraday configuration to its dependency gems that also have
        #       # nil configs. We can't be certain that each gem is configured
        #       # with the same Faraday config and need them synchronized, so we
        #       # inject them manually.
        #       OpenIDConnect.class_variable_set(:@@http_config, config_proc)
        #       WebFinger.instance_variable_set(:@http_config, config_proc)
        #       SWD.class_variable_set(:@@http_config, config_proc)
        #       Rack::OAuth2.class_variable_set(:@@http_config, config_proc)
        #     end

        #     d.call
        #   ensure
        #     symlink_a.each{ |s| File.unlink(s) if s.present? && File.symlink?(s) }
        #   end
        # end
      end
    end
  end
end
