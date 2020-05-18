# frozen_string_literal: true
require 'logs'

ENV["CONJUR_VERSION_DISPLAY"] = File.read(File.expand_path("../../VERSION", File.dirname(__FILE__)))

Rails.logger.info(LogMessages::Util::ConjurVersionStartup.new(ENV["CONJUR_VERSION_DISPLAY"].strip))
