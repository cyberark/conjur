# This cache refresh only based on failures to decode with cached certificate.
# That is, on fetch command, if parameter force_read is 'false' then return available
# object in cache. But if parameter force_read is 'true', i.e., the caller failed to decode
# with given certificate - only then read certificate from provider, but no more than
# NUM_MAX_RETRIES during the last RETRIES_TIME_LAP
# Note: there is no race condition between threads on using this singleton due to Ruby's GIL.

require 'singleton'

module Authentication
  module AuthnOidc
    class CertificateCache
      include Singleton

      attr_accessor :RETRIES_TIME_LAP
      attr_accessor :NUM_MAX_RETRIES

      def initialize()
        @NUM_MAX_RETRIES = 3
        @RETRIES_TIME_LAP = 3600
        clear_all
      end

      def clear_all
        @redis = {}
      end

      def fetch key, force_read = false, &block
        if not @redis.key?(key)
          # make the DB query and create a new entry for the request result
          @redis[key] = { value: yield(block), num_retries: 0, last_retry_time: Time.now.to_i }
        else
          force_read key, &block if force_read
        end
        @redis[key][:value]
      end

      private

      def force_read key, &block
        @redis[key][:num_retries] = @redis[key][:num_retries] + 1
        if ((Time.now.to_i - @redis[key][:last_retry_time]) > @RETRIES_TIME_LAP)
          @redis[key][:num_retries] = 1
          @redis[key][:last_retry_time] = Time.now.to_i
        end
        @redis[key][:value] = yield(block) if (@redis[key][:num_retries] <= @NUM_MAX_RETRIES)
      end

    end
  end
end