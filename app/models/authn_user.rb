require 'bcrypt'

class AuthnUser < Sequel::Model(:"authn__users")
  # Bcrypt work factor, minimum recommended work factor is 12
  BCRYPT_COST = 12

  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key

  attr_encrypted :api_key, aad: :login
  attr_encrypted :encrypted_hash, aad: :login
  
  class << self
    def random_api_key
      require 'base32/crockford'
      Slosilo::Random.salt.unpack("N*").map{|i| Base32::Crockford::encode(i)}.join.downcase
    end
    
    def account
      ENV['CONJUR_ACCOUNT'] or raise "No CONJUR_ACCOUNT available"
    end
  end
  
  def account; self.class.account; end
  
  def roleid
    kind, id = login.split('/', 2)
    if id.nil?
      kind = "user"
      id = login
    end
    [ account, kind, id ].join(":")
  end
  
  alias resourceid roleid
  
  def to_param
    require 'cgi'
    CGI.escape(login)
  end
  
  def as_json
    { login: login }
  end
  
  def password= pwd
    @plain_password = pwd
    self.encrypted_hash = pwd && BCrypt::Password.create(pwd, cost: BCRYPT_COST)
  end
  
  def authenticate pwd
    pwd && (pwd == api_key) || password_ok?(pwd)
  end
  
  def validate
    super

    errors.add(:password, 'cannot contain a newline') if @plain_password && @plain_password.index("\n")
    validates_presence [ :login, :api_key ]
  end
  
  def before_validation
    super
    
    self.api_key ||= self.class.random_api_key
  end
  
  def rotate_api_key
    self.api_key = self.class.random_api_key
  end
  
  private
  
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
