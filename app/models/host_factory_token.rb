class HostFactoryToken < Sequel::Model
  plugin :validation_helpers

  unrestrict_primary_key
  
  attr_encrypted :token
  many_to_one :resource, reciprocal: :host_factory_tokens

  alias host_factory resource
  
  class << self
    # Generates a random token.
    #
    # @return [String]
    def random_token
      require 'base32/crockford'
      Slosilo::Random.salt.unpack("N*").map{|i| Base32::Crockford::encode(i)}.join.downcase
    end

    # Finds the HostFactoryToken whose token is +token+.
    #
    # @return [HostFactoryToken]
    def from_token token
      require 'digest'
      where(token_sha256: Digest::SHA256.hexdigest(token)).all.find do |hft|
        hft.token == token
      end
    end
  end

  def as_json options = {}
    super(options.merge(except: [ :token, :token_sha256, :cidr, :expiration, :resource_id ])).tap do |response|
      response[:expiration] = expiration.utc.iso8601
      response[:cidr] = format_cidr
      response[:token] = token
    end
  end
  
  def valid?
    !expired?
  end

  def valid_origin? ip
    ip = IPAddr.new(ip)
    cidr.blank? || cidr.any? do |c|
      c.include?(ip)
    end
  end

  def expired?
    Time.now >= self.expiration
  end
  
  def validate
    super

    validates_presence [ :expiration]
  end

  def before_create
    super
    
    generate_token
  end
   
  private
  
  def format_cidr
    cidr.map do |c|
      c.is_a?(IPAddr) ? "#{c.to_s}/#{cidr_mask c}" : c.to_s
    end
  end

  # returns the length of the netmask in bits
  def cidr_mask cidr
    mask = cidr.instance_variable_get(:@mask_addr).to_s(2)[/\A(1*)0*\z/, 1]
    raise ArgumentError, "invalid IP mask in #{cidr.inspect}" if mask.nil?
    mask.length
  end

  def generate_token
    require 'digest'
    self.token = self.class.random_token
    self.token_sha256 = Digest::SHA256.hexdigest(self.token)
  end
end
