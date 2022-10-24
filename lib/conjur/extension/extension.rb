# frozen_string_literal: true

require 'set'

module Conjur
  module Extension
    # Extension::Extension represents the Conjur interface to call
    # extension points. It contains a set of classes that implement a particular
    # extension and proxies method calls to those classes. It does so with an
    # added safety of preventing errors in an extension from raising to the
    # calling process, or from preventing other extensions from being called.
    class Extension
      def initialize(
        implementations:,
        logger: Rails.logger
      )
        @logger = logger
        @implementations = implementations.to_set

        @logger.debug(
          "Extension::Extension - Using extension classes: " \
          "#{@implementations.map(&:name).join(', ')}"
        )
      end

      def call(method, **kwargs)
        @logger.debug(
          "Extension::Extension - Calling #{method}"
        )

        @implementations.each do |implementation|
          implementation.call(method, **kwargs)
        end
      end
    end
  end
end
