require 'openssl'

module Slosilo
  module Random
    class << self
      def salt
        OpenSSL::Random::random_bytes 32
      end
    end
  end
end
