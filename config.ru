# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

require 'prometheus/middleware/collector'
use Prometheus::Middleware::Collector, metrics_prefix: 'conjur_http_server'

run Rails.application
