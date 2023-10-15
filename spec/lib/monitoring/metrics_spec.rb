require 'monitoring/metrics'
require 'prometheus/client'

RSpec.describe Monitoring::Metrics do
  class MockMetric
    # does nothing
  end

  describe '#create_metric' do
    context 'with valid metric type' do
      it 'creates a gauge metric' do
        expect(Monitoring::Metrics).to receive(:create_gauge_metric).with(MockMetric)
        Monitoring::Metrics.create_metric(MockMetric, :gauge)
      end

      it 'creates a counter metric' do
        expect(Monitoring::Metrics).to receive(:create_counter_metric).with(MockMetric)
        Monitoring::Metrics.create_metric(MockMetric, :counter)
      end

      it 'creates a histogram metric' do
        expect(Monitoring::Metrics).to receive(:create_histogram_metric).with(MockMetric)
        Monitoring::Metrics.create_metric(MockMetric, :histogram)
      end

      it 'creates a histogram metric (string)' do
        expect(Monitoring::Metrics).to receive(:create_histogram_metric).with(MockMetric)
        Monitoring::Metrics.create_metric(MockMetric, 'histogram')
      end
    end

    context 'with invalid metric type' do
      it 'raises an error' do
        expect { Monitoring::Metrics.create_metric(MockMetric, :invalid_type) }
          .to raise_error(Errors::Monitoring::InvalidOrMissingMetricType)
      end
    end
  end
end
