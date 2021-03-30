module Conjur
  module PolicyParser
    module Logger
      def self.included base
        base.module_eval do
          # Override the logger with this method.
          cattr_accessor(:logger)
          
          require 'logger'
          self.logger = Logger.new($stderr)
          logger.level = (ENV['DEBUG'] == "true" ? Logger::DEBUG : Logger::INFO)
        end
      end
    end
  end
end
