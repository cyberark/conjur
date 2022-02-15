# encoding: UTF-8
require 'spec_helper'
require 'rack/test'
require 'prometheus/client/formats/text'
require ::File.expand_path('../../../lib/monitoring/metrics_client.rb', __FILE__)

describe Monitoring::MetricsClient do
  include Rack::Test::Methods

  it 'creates a valid registry and allows metrics' do
    mc = Monitoring::MetricsClient.new
    gauge = mc.registry.gauge(:room_temperature_celsius, docstring: '...', labels: [:room])
    gauge.set(21.534, labels: { room: 'kitchen' })
    gauge.get(labels: { room: 'kitchen' })

    expect(gauge.get(labels: { room: 'kitchen' })).to eql(21.534)
  end

end