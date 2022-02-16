# encoding: UTF-8
require 'spec_helper'
require 'rack/test'
require 'prometheus/client/formats/text'
require ::File.expand_path('../../../lib/monitoring/metrics.rb', __FILE__)

describe Monitoring::Metrics do
  include Rack::Test::Methods

  # it 'creates a valid registry and allows metrics' do
  #   mc = Monitoring::Metrics.new
  #   gauge = mc.registry.gauge(:foo, docstring: '...', labels: [:bar])
  #   gauge.set(21.534, labels: { bar: 'test' })

  #   expect(gauge.get(labels: { bar: 'test' })).to eql(21.534)
  # end

end