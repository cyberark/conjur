# frozen_string_literal: true

module Authentication
  module AuthnLdap
    # Provides the LDAP connections settings for a given
    # authenticator config
    class Configuration

      def initialize(input, env, log: nil)
        @input = input
        @env = env
        @log = log
      end

      def settings
        {
          connect_type: connect_type,
          host: host,
          port: port,
          base: base_dn,
          auth: auth,
          encryption: encryption,
          instrumentation_service: log
        }.reject { |_, value| value == :not_configured }
      end

      def filter_template
        ConfigurationLoader.load(
          AnnotationLoader.new(@input, "filter_template"),
          EnvironmentLoader.new(@env, "LDAP_FILTER"),
          default: "(&(objectClass=posixAccount)(uid=%s))"
        )
      end

      private 

      def log
        @log || :not_configured
      end

      def auth
        return :not_configured unless bind_dn

        {
          method: :simple,
          username: bind_dn,
          password: bind_pw
        }
      end

      def encryption
        return :not_configured unless connect_type_secure?

        {
          method: connect_type_ssl? ? :simple_tls : :start_tls,
          tls_options: tls_options
        }
      end

      def tls_options
        {
          verify_mode: OpenSSL::SSL::VERIFY_PEER,
          cert_store: LdapCaStore.new(tls_ca_cert).store
        }
      end

      def host
        ConfigurationLoader.load(
          AnnotationLoader.new(@input, "host"),
          default: uri.host
        )
      end

      def port
        ConfigurationLoader.load(
          AnnotationLoader.new(@input, "port"),
          default: uri.port || default_port
        )
      end

      def default_port
        connect_type_ssl? ? 636 : 389
      end

      # One of 'plain', 'tls', or 'ssl'
      def connect_type
        ConfigurationLoader.load(
          AnnotationLoader.new(@input, "connect_type"),
          default: uri_connect_type,
          &:to_sym
        )
      end

      def connect_type_secure?
        %i[ssl tls].include?(connect_type)
      end

      def uri_connect_type
        uri.scheme == 'ldaps' ? :ssl : :plain
      end

      def connect_type_ssl?
        connect_type == :ssl
      end

      def uri
        ConfigurationLoader.load(
          AnnotationLoader.new(@input, "uri"),
          EnvironmentLoader.new(@env, "LDAP_URI"),
          default: ''
        ) { |uri_str| URI(uri_str)}
      end

      def base_dn
        ConfigurationLoader.load(
          AnnotationLoader.new(@input, "base_dn"),
          EnvironmentLoader.new(@env, "LDAP_BASE"),
          default: :not_configured
        ) 
      end

      def bind_dn
        ConfigurationLoader.load(
          AnnotationLoader.new(@input, "bind_dn"),
          EnvironmentLoader.new(@env, "LDAP_BINDDN")
        )
      end

      def bind_pw
        ConfigurationLoader.load(
          VariableLoader.new(@input, "bind-password"),
          EnvironmentLoader.new(@env, "LDAP_BINDPW")
        )
      end

      def tls_ca_cert
        # "tls-ca-cert" is the correct annotation, "tls-cert" is allowed
        # for compatibility with LDAP sync legacy annotations
        ConfigurationLoader.load(
          VariableLoader.new(@input, "tls-ca-cert"),
          VariableLoader.new(@input, "tls-cert")
        )
      end     
    end

    # Specialized CA store for LDAP configuration
    class LdapCaStore
      class << self
        def create_cert_file(ca_cert)
          Tempfile.new('ca-cert').tap do |ca_cert_file|
            ca_cert_file.write(ca_cert)
            ca_cert_file.close
          end
        end
      end

      def initialize(ca_cert)
        @ca_cert = ca_cert
      end
      
      def store
        @store ||= build_store
      end

      private

      def build_store
        OpenSSL::X509::Store.new.tap do |cert_store|
          cert_store.set_default_paths
          cert_store.add_file(self.class.create_cert_file(@ca_cert).path) if @ca_cert
        end
      rescue OpenSSL::X509::StoreError => ex
        raise ArgumentError, "Invalid CA certificate in LDAP configuration: #{ex.message}"
      end
    end
  end
end
