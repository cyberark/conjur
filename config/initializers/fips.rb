require "openssl"
require "digest"

# Suppress warning messages
original_verbose, $VERBOSE = $VERBOSE, nil

# override the default Digest with OpenSSL::Digest
Digest::SHA256 = OpenSSL::Digest::SHA256
Digest::SHA1 = OpenSSL::Digest::SHA1

# Activate warning messages again
$VERBOSE = original_verbose

# by default FIPS mode is enabled
# disable FIPS mode only if OPENSSL_FIPS_ENABLED environment variable is present and has false value
OpenSSL.fips_mode = !(ENV["OPENSSL_FIPS_ENABLED"].present? && ENV["OPENSSL_FIPS_ENABLED"] == 'false')

# each of the following 3rd party overridden is required since a non FIPS complaint encryption method is used
# if a non-complaint FIPS method like MD5 is used or a direct use of Digest::encryption-method
#  (rather than OpenSSL::Digest::encryption-method) is performed
#  the server will crush on run time

# override ActiveSupport hash_digest_class with FIPS complaint method
ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest::SHA1.new
