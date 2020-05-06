require "openssl"
require "digest"
require "digest/md5"
require "digest/sha1"
require 'sprockets'
require 'openid_connect'

# Suppress warning messages
original_verbose, $VERBOSE = $VERBOSE, nil

# Remove pre-existing constants if they do exist to reduce the amount of log spam and warnings
Digest.send(:remove_const, "MD5") if Digest.const_defined?("MD5")
Digest.const_set("MD5", OpenSSL::Digest::MD5)
Digest.send(:remove_const, "SHA1") if Digest.const_defined?("SHA1")
Digest.const_set("SHA1", OpenSSL::Digest::SHA1)
Digest.send(:remove_const, "SHA256") if Digest.const_defined?("SHA256")
Digest.const_set("SHA256", OpenSSL::Digest::SHA256)

# override the default Digest with OpenSSL::Digest
Digest::SHA256 = OpenSSL::Digest::SHA256
Digest::SHA1 = OpenSSL::Digest::SHA1

# Activate warning messages again
$VERBOSE = original_verbose

# enable FIPS mode
OpenSSL.fips_mode = true

# each of the following 3rd party overridden is required since a non FIPS complaint encryption method is used
# if a non-complaint FIPS method like MD5 is used or a direct use of Digest::encryption-method
#  (rather than OpenSSL::Digest::encryption-method) is performed
#  the server will crush on run time

# override ActiveSupport hash_digest_class with FIPS complaint method
ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest::SHA1.new

# override Sprockets digest_class with FIPS complaint method
Sprockets::DigestUtils.module_eval do
  def digest_class
    OpenSSL::Digest::SHA256
  end
end
Sprockets.config = Sprockets.config.merge(
    digest_class: OpenSSL::Digest::SHA256
).freeze

# override OpenIDConnect cache_key with FIPS complaint method
OpenIDConnect::Discovery::Provider::Config::Resource.module_eval do
  def cache_key
    sha256 = Digest::SHA256.hexdigest host
    "swd:resource:opneid-conf:#{sha256}"
  end
end
