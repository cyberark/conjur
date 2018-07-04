# frozen_string_literal: true

# Require at least TLSv1 due to POODLE. The way to specify a minimum
# version changed in ruby 2.5.
if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.5')
  OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = :TLSv1
else
  OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:min_version] = OpenSSL::SSL::TLS1_VERSION
end
