# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

require 'prometheus/middleware/collector'
#require 'prometheus/middleware/exporter'
require ::File.expand_path('../lib/metrics/custom_exporter.rb', __FILE__)

use Prometheus::Middleware::Collector
#use Prometheus::Middleware::Exporter
use Prometheus::Middleware::CustomExporter

run Rails.application
