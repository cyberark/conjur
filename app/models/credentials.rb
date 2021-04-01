# frozen_string_literal: true

require 'bcrypt'
require 'util/cidr'
require 'conjur/password'

# TODO: This is needed because having the same line config/application.rb is
# not working.  I wasn't able to figure out what precisely was going wrong,
# even after discussing with Jeremy Evans (sequel's author) on IRC, but bottom
# line: without this line the extensions aren't loaded.
#
Sequel::Model.db.extension(:pg_array, :pg_inet)

class Credentials < Sequel::Model
  # Bcrypt work factor, minimum recommended work factor is 12
  BCRYPT_COST = 12

  # special characters according to https://www.owasp.org/index.php/Password_special_characters
  VALID_PASSWORD_REGEX = %r{^(?=.*?[A-Z].*[A-Z])                             # 2 uppercase letters
                             (?=.*?[a-z].*[a-z])                             # 2 lowercase letters
                             (?=.*?[0-9])                                    # 1 digit
                             (?=.*[ !"#$%&'()*+,-./:;<=>?@\[\\\]^_`{|}~]).  # 1 special character
                             {12,128}$}x.freeze                                     # 12-128 characters

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

  def restricted_to
    self[:restricted_to].map { |cidr| Util::CIDR.new(cidr) }
  end

  def password= pwd
    @plain_password = pwd
    self.encrypted_hash = pwd && BCrypt::Password.create(pwd, cost: BCRYPT_COST)
  end

  def authenticate pwd
    valid_api_key?(pwd) || valid_password?(pwd)
  end

  def valid_password? pwd
    bc = BCrypt::Password.new(self.encrypted_hash)
    # This `==` is implemented by BCrypt' Password class (link:
    #     https://www.rubydoc.info/github/codahale/bcrypt-ruby/BCrypt/Password#==-instance_method)
    # The comparison occurs against two BCrypt hashes, thus, is not a timing attack concern
    if bc == pwd
      self.update(password: pwd) if bc.cost != BCRYPT_COST
      true
    else
      false
    end
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def valid_api_key? key
    return false if expired?

    key && ActiveSupport::SecurityUtils.secure_compare(key, api_key)
  end

  def validate
    super

    validates_presence([ :api_key ])

    # We intentionally don't validate when there is no password
    # See flow in Account.create
    return unless @plain_password

    unless Conjur::Password.valid?(@plain_password)
      errors.add(
        :password, ::Errors::Conjur::InsufficientPasswordComplexity.new.to_s
      )
    end
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
end
