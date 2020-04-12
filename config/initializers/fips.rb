require "openssl"
require "digest"
require "digest/sha1"
require "digest/md5"
require 'sprockets'
require 'openid_connect'

# override the default Digest with OpenSSL::Digest
Digest::SHA256 = OpenSSL::Digest::SHA256
Digest::SHA1 = OpenSSL::Digest::SHA1

OpenSSL.fips_mode = true
ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest::SHA1.new
Sprockets::DigestUtils.module_eval do
  def digest_class
    OpenSSL::Digest::SHA256
  end
end

new_sprockets_config = {}
Sprockets.config.each do |key, val|
  new_sprockets_config[key] = val
end
new_sprockets_config[:digest_class] = OpenSSL::Digest::SHA256
Sprockets.config = new_sprockets_config.freeze

OpenIDConnect::Discovery::Provider::Config::Resource.module_eval do
  def cache_key
    sha256 = Digest::SHA256.hexdigest host
    "swd:resource:opneid-conf:#{sha256}"
  end
end

# Remove pre-existing constants if they do exist to reduce the
# amount of log spam and warnings.
Digest.send(:remove_const, "SHA1") if Digest.const_defined?("SHA1")
Digest.const_set("SHA1", OpenSSL::Digest::SHA1)
OpenSSL::Digest.send(:remove_const, "MD5") if OpenSSL::Digest.const_defined?("MD5")
OpenSSL::Digest.const_set("MD5", Digest::MD5)