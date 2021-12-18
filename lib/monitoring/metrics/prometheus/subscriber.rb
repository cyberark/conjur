require 'prometheus/client'

module Monitoring
  module Metrics
    module Prometheus
      class Subscriber

        def initialize(metrics)
          @metrics = metrics
        end

        def call(log)
          log(log) if should_log?(log)
        end

        def log(log)
          # TODO: add exception if the passed metric was not found
          # in the hash of registered metrics.
          @metrics[log.metric.to_sym].call(
            value: log.duration,
            labels: {
              name: log.name,
              metric: log.metric
            }
          )
        end

        def should_log?(log)
          log.metric.present?
        end
      end
    end
  end
end
