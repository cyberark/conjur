# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

require ::File.expand_path('../lib/prometheus/custom_collector.rb', __FILE__)
use Prometheus::Middleware::CustomCollector

run Rails.application
