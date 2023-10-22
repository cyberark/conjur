require 'slosilo/key'

module Slosilo
  class Keystore
    def adapter
      Slosilo::adapter or raise "No Slosilo adapter is configured or available"
    end

    def put id, key
      id = id.to_s
      fail ArgumentError, "id can't be empty" if id.empty?
      adapter.put_key id, key
    end

    def get opts
      id, fingerprint = opts.is_a?(Hash) ? [nil, opts[:fingerprint]] : [opts, nil]
      if id
        key = adapter.get_key(id.to_s)
      elsif fingerprint
        key, _ = get_by_fingerprint(fingerprint)
      end
      key
    end

    @@get_by_fingerprint_result = Hash.new
    #@@semaphore = Mutex.new

    def get_by_fingerprint fingerprint
      #@@semaphore.synchronize do
        if (@@get_by_fingerprint_result[fingerprint].nil?)
          @@get_by_fingerprint_result[fingerprint] = adapter.get_by_fingerprint fingerprint
        end
        return @@get_by_fingerprint_result[fingerprint]
      #end
    end

    def each &_
      adapter.each { |k, v| yield k, v }
    end

    def any? &block
      each do |_, k|
        return true if yield k
      end
      return false
    end
  end

  class << self
    def []= id, value
      keystore.put id, value
    end

    def [] id
      keystore.get id
    end

    def each(&block)
      keystore.each(&block)
    end

    def sign object
      self[:own].sign object
    end

    def token_valid? token
      keystore.any? { |k| k.token_valid? token }
    end

    # Looks up the signer by public key fingerprint and checks the validity
    # of the signature. If the token is JWT, exp and/or iat claims are also
    # verified; the caller is responsible for validating any other claims.
    def token_signer token
      begin
        # see if maybe it's a JWT
        token = JWT token
        fingerprint = token.header['kid']
      rescue ArgumentError
        fingerprint = token['key']
      end

      key, id = keystore.get_by_fingerprint fingerprint
      if key && key.token_valid?(token)
        return id
      else
        return nil
      end
    end

    attr_accessor :adapter

    private
    def keystore
      @keystore ||= Keystore.new
    end
  end
end
