require 'bcrypt'

class Credentials < Sequel::Model
  # Bcrypt work factor, minimum recommended work factor is 12
  BCRYPT_COST = 12

  plugin :validation_helpers

  unrestrict_primary_key

  many_to_one :role, reciprocal: :credentials
  many_to_one :client, class: :Role

  attr_encrypted :api_key, aad: :role_id
  attr_encrypted :encrypted_hash, aad: :role_id
  
  class << self
    def random_api_key
      require 'base32/crockford'
      Slosilo::Random.salt.unpack("N*").map{|i| Base32::Crockford::encode(i)}.join.downcase
    end
  end
  
  def as_json
    { }
  end
  
  def password= pwd
    @plain_password = pwd
    self.encrypted_hash = pwd && BCrypt::Password.create(pwd, cost: BCRYPT_COST)
  end

  def authenticate pwd
    valid_api_key?(pwd) || valid_password?(pwd)
  end

  def valid_password? pwd
    password_ok?(pwd)
  end

  def valid_api_key? key
    return false if expired?
    key && (key == api_key) 
  end
  
  def validate
    super

    errors.add(:password, 'cannot contain a newline') if @plain_password && @plain_password.index("\n")
    validates_presence [ :api_key ]
  end
  
  def before_validation
    super
    
    self.api_key ||= self.class.random_api_key
  end
  
  def rotate_api_key
    self.api_key = self.class.random_api_key
  end
  
  private
  
  def expired?
    return false unless self.expiration
    
    self.expiration <= Time.now
  end
  
  def password_ok? pwd
    bc = BCrypt::Password.new(self.encrypted_hash) rescue nil
    if bc && !bc.blank? && bc == pwd
      self.update password: pwd if bc.cost != BCRYPT_COST
      return true
    else
      return false
    end
  end
end
