require 'json'

module Slosilo
  # A JWT-formatted Slosilo token.
  # @note This is not intended to be a general-purpose JWT implementation.
  class JWT
    # Create a new unsigned token with the given claims.
    # @param claims [#to_h] claims to embed in this token.
    def initialize claims = {}
      @claims = JSONHash[claims]
    end

    # Parse a token in compact representation
    def self.parse_compact raw
      load *raw.split('.', 3).map(&Base64.method(:urlsafe_decode64))
    end

    # Parse a token in JSON representation.
    # @note only single signature is currently supported.
    def self.parse_json raw
      raw = JSON.load raw unless raw.respond_to? :to_h
      parts = raw.to_h.values_at(*%w(protected payload signature))
      fail ArgumentError, "input not a complete JWT" unless parts.all?
      load *parts.map(&Base64.method(:urlsafe_decode64))
    end

    # Add a signature.
    # @note currently only a single signature is handled;
    # the token will be frozen after this operation.
    def add_signature header, &sign
      @claims = canonicalize_claims.freeze
      @header = JSONHash[header].freeze
      @signature = sign[string_to_sign].freeze
      freeze
    end

    def string_to_sign
      [header, claims].map(&method(:encode)).join '.'
    end

    # Returns the JSON serialization of this JWT.
    def to_json *a
      {
        protected: encode(header),
        payload: encode(claims),
        signature: encode(signature)
      }.to_json *a
    end

    # Returns the compact serialization of this JWT.
    def to_s
      [header, claims, signature].map(&method(:encode)).join('.')
    end

    attr_accessor :claims, :header, :signature

    private

    # Create a JWT token object from existing header, payload, and signature strings.
    # @param header [#to_s] URLbase64-encoded representation of the protected header
    # @param payload [#to_s] URLbase64-encoded representation of the token payload
    # @param signature [#to_s] URLbase64-encoded representation of the signature
    def self.load header, payload, signature
      self.new(JSONHash.load payload).tap do |token|
        token.header = JSONHash.load header
        token.signature = signature.to_s.freeze
        token.freeze
      end
    end

    def canonicalize_claims
      claims[:iat] = Time.now unless claims.include? :iat
      claims[:iat] = claims[:iat].to_time.to_i
      claims[:exp] = claims[:exp].to_time.to_i if claims.include? :exp
      JSONHash[claims.to_a]
    end

    # Convenience method to make the above code clearer.
    # Converts to string and urlbase64-encodes.
    def encode s
      Base64.urlsafe_encode64 s.to_s
    end

    # a hash with a possibly frozen JSON stringification
    class JSONHash < Hash
      def to_s
        @repr || to_json
      end

      def freeze
        @repr = to_json.freeze
        super
      end

      def self.load raw
        self[JSON.load raw.to_s].tap do |h|
          h.send :repr=, raw
        end
      end

      private

      def repr= raw
        @repr = raw.freeze
        freeze
      end
    end
  end

  # Try to convert by detecting token representation and parsing
  def self.JWT raw
    if raw.is_a? JWT
      raw
    elsif raw.respond_to?(:to_h) || raw =~ /\A\s*\{/
      JWT.parse_json raw
    else
      JWT.parse_compact raw
    end
  rescue
    raise ArgumentError, "invalid value for JWT(): #{raw.inspect}"
  end
end
