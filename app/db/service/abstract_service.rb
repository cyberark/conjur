# frozen_string_literal: true

require 'singleton'

module DB
  module Service
    class AbstractService
      include Singleton


      def initialize
        @logger = Rails.logger
      end

    end
  end
end
