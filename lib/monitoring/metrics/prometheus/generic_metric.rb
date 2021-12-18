# A class which provides a generic interface for the various types of metrics supported by
# by Prometheus. Currently, these include:
#   - Histogram
#   - Gauge
#   - Counter

require 'prometheus/client'

module Monitoring
  module Metrics
    module Prometheus
      class GenericMetric
        attr_reader :metric

        def initialize(metric:)
          @metric = metric
          # binding.pry
          @call_method = call_method(metric)
        end

        def call(value:, labels:)
          @metric.send(@call_method, value, labels: labels)
        end

        private

        def call_method(klass)
          # Case statements don't like the root scoped class names
          if klass.is_a?(::Prometheus::Client::Histogram)
            :observe
          elsif klass.is_a?(::Prometheus::Client::Gauge)
            :set
          elsif klass.is_a?(::Prometheus::Client::Counter)
            :increment
          end
        end
      end
    end
  end
end
