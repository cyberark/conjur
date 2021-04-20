require 'prometheus/middleware/exporter'

module Prometheus
  module Middleware
    class CustomExporter < Prometheus::Middleware::Exporter
      def respond_with(format)
        gauge = @registry.metrics.first
        gauge.set(rand(100), labels: {name: :test, env: Rails.env, description: "Test gauge"})

        super
      end

    end
  end
end
