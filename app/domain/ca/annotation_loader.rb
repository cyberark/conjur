module CA
  # Responsible for retrieving values both directly from annotation
  # and from Conjur variables that annotations may reference.
  class AnnotationLoader
    # Provides helper method for loading an RSA private key annotation
    module RsaPrivateKey
      def load_rsa_private_key(annotation_loader)
        key_data = annotation_loader.variable('ca/private-key')

        unless key_data.present?
          raise ArgumentError, "The private key (ca/private-key) for '#{service_id}' is missing."
        end
          
        password = annotation_loader.variable('ca/private-key-password')

        OpenSSL::PKey::RSA.new(key_data, password)
      end
    end

    # Provides helper method for loading a max TTL annotation
    module MaxTTL
      def load_max_ttl(annotation_loader)
        max_ttl = annotation_loader.raw('ca/max-ttl') { |val| ISO8601::Duration.new(val).to_seconds.to_i }

        unless max_ttl.present?
          raise ArgumentError, "The max TTL (ca/max-ttl) for '#{service_id}' is missing." 
        end

        max_ttl
      end
    end

    def initialize(resource)
      @resource = resource
    end

    def annotations
      @annotations = @resource.annotations
        .reduce([]) { |all, current| all << [current[:name], current[:value]] }
        .to_h 
    end

    def raw(name)
      annotations[name].try { |val| block_given? ? yield(val) : val}
    end

    def variable(name)
      raw(name).try { |val| self.class.load_variable(@resource.account, val) }
        .try { |var_val| block_given? ? yield(var_val) : var_val }
    end

    # :reek:NilCheck
    def self.load_variable(account, identifier)
      variable_id = [
        account,
        'variable',
        identifier
      ].join(':')

      Resource[variable_id]&.secret&.value
    end
  end
end
