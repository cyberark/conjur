
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

      def self.read_count_from(key)
        val = 0
        begin
          val = Rails.cache.read(key, raw: true).to_i
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
          Rails.cache.write(key, value, expires_in: nil)
          if (zero_key != "")
            Rails.cache.write(zero_key, 0, expires_in: nil, raw: true)
          end
        rescue Redis::BaseError => e
          # Catch any Redis-related exceptions
          Rails.logger.info( "Error connecting to Redis: #{e.message}")
        end
      end

      def self.increment_counter_cache(key)
        begin
          val = Rails.cache.increment(key, expires_in: nil)
        rescue Redis::BaseError => e
          # Catch any Redis-related exceptions
          Rails.logger.info("Error connecting to Redis: #{e.message}")
        rescue ApplicationController::ServiceUnavailable => e
          # Catch any Redis-related exceptions
          Rails.logger.info("Error connecting to Redis: #{e.message}")
        end
        val
      end
    end

end
