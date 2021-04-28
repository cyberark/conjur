# frozen_string_literal: true

require 'logs'

ENV["CONJUR_VERSION_DISPLAY"] = File.read(File.expand_path("../../VERSION", File.dirname(__FILE__)))
ENV["API_VERSION"] = File.read(File.expand_path("../../API_VERSION", File.dirname(__FILE__)))
