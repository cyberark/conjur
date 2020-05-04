require "openssl"
require "digest"
require "digest/md5"
require "digest/sha1"
require 'sprockets'
require 'openid_connect'

# Supress warning messages.
original_verbose, $VERBOSE = $VERBOSE, nil
# Remove pre-existing constants if they do exist to reduce the
# amount of log spam and warnings.
Digest.send(:remove_const, "MD5") if Digest.const_defined?("MD5")
Digest.const_set("MD5", OpenSSL::Digest::MD5)
Digest.send(:remove_const, "SHA1") if Digest.const_defined?("SHA1")
Digest.const_set("SHA1", OpenSSL::Digest::SHA1)
Digest.send(:remove_const, "SHA256") if Digest.const_defined?("SHA256")
Digest.const_set("SHA256", OpenSSL::Digest::SHA256)

# override the default Digest with OpenSSL::Digest
Digest::SHA256 = OpenSSL::Digest::SHA256
Digest::SHA1 = OpenSSL::Digest::SHA1
# Activate warning messages again.
$VERBOSE = original_verbose

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