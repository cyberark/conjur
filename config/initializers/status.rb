# frozen_string_literal: true

ENV["CONJUR_VERSION_APPLIANCE"] = File.read(File.expand_path("../../VERSION_APPLIANCE", File.dirname(__FILE__)))
ENV["CONJUR_VERSION_DISPLAY"] = File.read(File.expand_path("../../VERSION", File.dirname(__FILE__)))
