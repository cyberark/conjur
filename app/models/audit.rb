# frozen_string_literal: true

require 'audit/log/ruby_adapter'

module Audit
  class << self
    def logger
      @logger ||= Log::RubyAdapter.new(Rails.logger)
    end

    attr_writer :logger
  end
end
