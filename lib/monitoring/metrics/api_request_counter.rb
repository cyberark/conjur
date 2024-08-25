require 'util/redis_cache'
require_relative '../operations'
require 'time'

module Monitoring
  module Metrics
    class ApiRequestCounter
      attr_reader :registry, :pubsub, :metric_name, :docstring, :labels, :sub_event_name

      def setup(registry, pubsub)
        @registry = registry
        @pubsub = pubsub
        @metric_name = :conjur_requests_total
        @docstring = 'The total number of HTTP requests handled by Conjur.'
        # labels should be only in alphabetic order
        @labels = %i[environment operation tenant_id]
        @sub_event_name = 'conjur.request'

        # Create/register the metric
        Metrics.create_metric(self, :gauge)

        if ENV['TENANT_ID'].nil?
          ENV['TENANT_ID'] = ""
        end

      end

      def refresh(registry)
        @metric_name = :conjur_requests_total
        operation = "getSecret"
        key = operation + "/counter"
        time_hour_key = operation + "/time_hour"

        last_time_hour = Util::RedisCache.read_from(time_hour_key)
        current_time_hour = Time.now.hour
        if (current_time_hour != last_time_hour)
          Util::RedisCache.write_to(time_hour_key, current_time_hour, key)
        end
        val = Util::RedisCache.read_count_from(key)
        # labels should be only in alphabetic order
        update_labels = {
          environment: ENV['TENANT_ENV'],
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

        return unless Monitoring::Metrics::LOGGED_OPERATIONS.include?(payload[:operation].to_sym)

        metric = registry.get(metric_name)
        # labels should be only in alphabetic order
        update_labels = {
          environment: ENV['TENANT_ENV'],
          operation: payload[:operation],
          tenant_id: ENV['TENANT_ID']
        }

        key = payload[:operation] + "/counter"
        val = Util::RedisCache.increment_counter_cache(key)
        metric.set(val , labels: update_labels)

      end
    end
  end
end
