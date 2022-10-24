# frozen_string_literal: true

require_relative './implementation_method'

module Conjur
  module Extension
    # Extension::Implementation is a proxy wrapper around a Conjur extension
    # class. It handles instantiating an instance of the extension class and
    # proxying method calls to it through `#call`.
    class Implementation

      def self.from_extension_class(
        extension_class,
        logger: Rails.logger,
        **kwargs
      )
        # Instantiate the extension class
        implementation = ImplementationMethod.new(
          # For the constructore, we're looking for the method on the class
          # itself, rather than an instance of it.
          implementation_object: extension_class,
          method: :new,
          # These are dependencies the extension may use in its
          # implementation. At a minimum, extension initializers must include
          # a **kwargs initializer argument to consume any arguments it
          # doesn't declare specifically.
          logger: logger,
          **kwargs
        ).call

        # Wrap the extension object with an Implementation proxy interface
        Implementation.new(
          implementation_object: implementation,
          logger: logger
        )
      end

      def initialize(
        implementation_object:,
        logger: Rails.logger
      )
        @implementation_object = implementation_object
        @logger = logger
      end

      def name
        @implementation_object.class.name
      end

      # Extension implementations are comparable by their class names
      def hash
        name.hash
      end

      def eql?(other)
        name == other.name
      end

      # We use :reek:ManualDispatch to proxy the given method to each of the
      # extension classes.
      def call(method, **kwargs)
        unless @implementation_object.respond_to?(method)
          @logger.debug(
            "Extension::Implementation#call - " \
            "'#{implementation_class_name}' doesn't respond to " \
            "'#{method}'"
          )
          return
        end

        @logger.debug(
          "Extension::Implementation#call - Calling '#{method}' on " \
          "'#{implementation_class_name}'"
        )
        begin
          ImplementationMethod.new(
            implementation_object: @implementation_object,
            method: method,
            **kwargs
          ).call
        rescue => e
          # Failed extension calls do not bubble up exceptions. They are
          # logged, but otherwise ignored by Conjur. Exceptions in extensions
          # should be fully handled in the extension implementation itself.
          @logger.error(
            "Extension::Implementation - Failed to call '#{method}' on " \
            "'#{implementation_class_name}': #{e.message}"
          )
        end
      end

      protected

      def implementation_class_name
        @implementation_object.class.name
      end
    end
  end
end
