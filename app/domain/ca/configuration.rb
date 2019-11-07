module CA
  # Responsible for retrieving values both directly from annotation
  # and from Conjur variables that annotations may reference.
  class Configuration
    def initialize(resource)
      @resource = resource
    end

    def rsa_private_key
      key_data = variable('ca/private-key')

      if key_data.to_s.strip.empty?
        raise ArgumentError, "The private key (ca/private-key) for '#{service_id}' is missing."
      end
        
      password = variable('ca/private-key-password')

      OpenSSL::PKey::RSA.new(key_data, password)
    end

    def max_ttl
      max_ttl = raw('ca/max-ttl') { |val| ISO8601::Duration.new(val).to_seconds.to_i }

      unless max_ttl
        raise ArgumentError, "The max TTL (ca/max-ttl) for '#{service_id}' is missing." 
      end

      max_ttl
    end

    def annotations
      @annotations = @resource.annotations
        .reduce([]) { |all, current| all << [current[:name], current[:value]] }
        .to_h 
    end

    def raw(name, &block)
      # Annotation doesn't exist
      annotation_value = annotations[name]
      return nil unless annotation_value

      transform_value(annotation_value, &block)
    end

    # A variable configuration looks of a variable ID in the annotation
    # name given.
    def variable(name, &block)
      # Annotation doesn't exist
      annotation_value = raw(name)
      return nil unless annotation_value

      # Variable doesn't exist or has no value set
      variable_value = self.class.load_variable(@resource.account, annotation_value)
      return nil unless variable_value

      transform(variable_value, &block)
    end

    # Transforms a value with the given block. If
    # no block is supplied, this simply returns
    # the value
    def transform_value(value)
      block_given? ? yield(value) : value
    end

    # :reek:NilCheck
    def self.load_variable(account, identifier)
      variable_id = [ account, 'variable', identifier ].join(':')

      Resource[variable_id]&.secret&.value
    end
  end
end
