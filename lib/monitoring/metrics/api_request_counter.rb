module Monitoring
  module Metrics
    class ApiRequestCounter
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_requests_total
        @docstring = 'The total number of HTTP requests handled by Conjur.'
        @labels = %i[operation tenant_id]
        @sub_event_name = 'conjur.request'

        # Create/register the metric
        Metrics.create_metric(self, :gauge)

        if ENV['TENANT_ID'].nil?
          ENV['TENANT_ID'] = ""
        end

      end

      def read_from_cache(key)
        val = 0
        begin
          val = Rails.cache.read(key)
        rescue Redis::BaseError => e
          # Catch any Redis-related exceptions
          puts "Error connecting to Redis: #{e.message}"
        end
        if (val.nil?)
          val = 0
        end
        val
      end

      def write_date_cache(date_key, current_date, key)
        begin
          Rails.cache.write(date_key, current_date)
          Rails.cache.write(key, 0)
        rescue Redis::BaseError => e
          # Catch any Redis-related exceptions
          Rails.logger.info( "Error connecting to Redis: #{e.message}")
        end
      end

      def write_counter_cache(key, val)
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

      def refresh(registry)

        @metric_name = :conjur_requests_total
        operation = "getSecret"
        key = operation + "/counter"
        date_key = operation + "/date"

        last_date = read_from_cache(date_key)
        current_date = Date.today
        if (current_date != last_date)
          write_date_cache(date_key, current_date, key)
        end

        val = read_from_cache(key)
        update_labels = {
          operation: operation,
          tenant_id: ENV['TENANT_ID']
        }
        metric = registry.get(metric_name)
        unless (metric.nil?)
          metric.set(val, labels: update_labels)
        end

      end


      def update(payload)

        if ((payload[:operation] == 'unknown') || (payload[:operation] == 'getMetrics'))
          return
        end

        if (payload[:operation] != "getSecret")
          return
        end

        metric = registry.get(metric_name)
        update_labels = {
          operation: payload[:operation],
          tenant_id: ENV['TENANT_ID']
        }

        key = payload[:operation] + "/counter"

        val = read_from_cache(key)

        write_counter_cache(key, val)
        val = val + 1;
        metric.set(val , labels: update_labels)

      end
    end
  end
end
