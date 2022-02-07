# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

#require 'rack'
require ::File.expand_path('../lib/monitoring/middleware/conjur_collector.rb', __FILE__)
require ::File.expand_path('../lib/monitoring/middleware/conjur_exporter.rb', __FILE__)

#use Rack::Deflater
use Prometheus::Middleware::ConjurCollector
use Prometheus::Middleware::ConjurExporter

run Rails.application
