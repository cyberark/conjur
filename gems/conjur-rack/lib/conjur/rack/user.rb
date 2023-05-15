require 'conjur/api'

module Conjur
  module Rack
    # Token data can be a string (which is the user login), or a Hash.
    # If it's a hash, it should contain the user login keyed by the string 'login'.
    # The rest of the payload is available as +attributes+.
    class User
      attr_reader :token, :account, :privilege, :remote_ip, :audit_roles, :audit_resources
      
      def initialize(token, account, options = {})
        @token = token
        @account = account
        # Third argument used to be the name of privilege, be
        # backwards compatible:
        if options.respond_to?(:to_str)
          @privilege = options
        else
          @privilege = options[:privilege]
          @remote_ip = options[:remote_ip]
          @audit_roles = options[:audit_roles]
          @audit_resources = options[:audit_resources]
        end
      end
      
      # This file was accidently calling account conjur_account,
      # I'm adding an alias in case that's going on anywhere else.
      # -- Jon
      alias :conjur_account :account
      # alias :conjur_account= :account=
      
      # Returns the global privilege which was present on the request, if and only
      # if the user actually has that privilege.
      #
      # Returns nil if no global privilege was present in the request headers, 
      # or if a global privilege was present in the request headers, but the user doesn't
      # actually have that privilege according to the Conjur server.
      def validated_global_privilege
        unless @validated_global_privilege
          @privilege = nil unless @privilege &&
                  api.respond_to?(:global_privilege_permitted?) &&
                  api.global_privilege_permitted?(@privilege)
          @validated_global_privilege = true
        end
        @privilege
      end
      
      # True if and only if the user has valid global 'reveal' privilege.
      def global_reveal?
        validated_global_privilege == "reveal"
      end
      
      # True if and only if the user has valid global 'elevate' privilege.
      def global_elevate?
        validated_global_privilege == "elevate"
      end
      
      def login
        parse_token

        @login
      end

      def attributes
        parse_token

        @attributes || {}
      end
      
      def roleid
        tokens = login.split('/')
        role_kind, roleid = if tokens.length == 1
          [ 'user', login ]
        else
          [ tokens[0], tokens[1..-1].join('/') ]
        end
        [ account, role_kind, roleid ].join(':')
      end
      
      def role
        api.role(roleid)
      end

      def audit_resources
        Conjur::API.decode_audit_ids(@audit_resources) if @audit_resources
      end

      def audit_roles
        Conjur::API.decode_audit_ids(@audit_roles) if @audit_roles
      end

      def api(cls = Conjur::API)
        args = [ token ]
        args.push remote_ip if remote_ip
        api = cls.new_from_token(*args)

        # These are features not present in some API versions.
        # Test for them and only apply if it makes sense. Ignore otherwise.
        %i(privilege audit_resources audit_roles).each do |feature|
          meth = "with_#{feature}".intern
          if api.respond_to?(meth) && (value = send(feature))
            api = api.send meth, value
          end
        end

        api
      end

      protected

      def parse_token
        return if @login

        @token = Slosilo::JWT token
        load_jwt token
      rescue ArgumentError
        if data = token['data']
          return load_legacy data
        else
          raise "malformed token"
        end
      end

      def load_legacy data
        if data.is_a?(String)
          @login = token['data']
        elsif data.is_a?(Hash)
          @attributes = token['data'].clone
          @login = @attributes.delete('login') or raise "No 'login' field in token data"
        else
          raise "Expecting String or Hash token data, got #{data.class.name}"
        end
      end

      def load_jwt jwt
        @attributes = jwt.claims.merge (jwt.header || {}) # just pass all the info
        @login = jwt.claims['sub'] or raise "No 'sub' field in claims"
      end
    end
  end
end
