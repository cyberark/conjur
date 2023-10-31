require "openssl"
require "digest"
require "ffi"

# Suppress warning messages
original_verbose = $VERBOSE
$VERBOSE = nil

# override the default Digest with OpenSSL::Digest
Digest::SHA256 = OpenSSL::Digest::SHA256
Digest::SHA1 = OpenSSL::Digest::SHA1

# Activate warning messages again
$VERBOSE = original_verbose

# This is a temporary workaround to support OpenSSL v3 until ruby openssl gem properly handles fips mode state
# https://github.com/ruby/openssl/issues/369
if OpenSSL::OPENSSL_LIBRARY_VERSION.start_with?("OpenSSL 3")
  module OpenSSL
    extend FFI::Library
      ffi_lib 'libssl.so'
      attach_function :EVP_default_properties_is_fips_enabled, [:pointer], :int

    def self.fips_mode
      EVP_default_properties_is_fips_enabled(nil) == 1
    end

    def self.fips_mode=(mode)
      raise "Changing FIPS state in OpenSSL 3 needs to be done with OpenSSL configuration"
    end
  end
else
  # by default FIPS mode is enabled
  # disable FIPS mode only if OPENSSL_FIPS_ENABLED environment variable is present and has false value
  OpenSSL.fips_mode = !(ENV.fetch('OPENSSL_FIPS_ENABLED', 'true') == 'false')
end

# each of the following 3rd party overridden is required since a non FIPS complaint encryption method is used
# if a non-complaint FIPS method like MD5 is used or a direct use of Digest::encryption-method
#  (rather than OpenSSL::Digest::encryption-method) is performed
#  the server will crush on run time

# override ActiveSupport hash_digest_class with FIPS complaint method
ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest.new('SHA1')
