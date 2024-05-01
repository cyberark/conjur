
module Util
  # provides helper methods for interacting Redis cache
  class RedisCache

      def self.read_from(key)
        val = 0
        begin
          val = Rails.cache.read(key)
        rescue Redis::BaseError => e
          # Catch any Redis-related exceptions
          Rails.logger.info("Error connecting to Redis: #{e.message}")
        end
        if (val.nil?)
          val = 0
        end
        val
      end

      def self.write_to(key, value, zero_key = "")
        begin
          Rails.cache.write(key, value)
          if (zero_key != "")
            Rails.cache.write(key, 0)
          end
        rescue Redis::BaseError => e
          # Catch any Redis-related exceptions
          Rails.logger.info( "Error connecting to Redis: #{e.message}")
        end
      end

      def self.increment_counter_cache(key, val)
        begin
          if (val == 0)
            Rails.cache.write(key, 1)
          else
            Rails.cache.increment(key)
          end
        rescue Redis::BaseError => e
          # Catch any Redis-related exceptions
          Rails.logger.info("Error connecting to Redis: #{e.message}")
        rescue ApplicationController::ServiceUnavailable => e
          # Catch any Redis-related exceptions
          Rails.logger.info("Error connecting to Redis: #{e.message}")
        end
      end
    end

end
