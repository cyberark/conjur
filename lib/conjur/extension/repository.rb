# frozen_string_literal: true

require_relative './extension'
require_relative './implementation'

module Conjur
  module Extension
    # Extension::Repository loads Conjur extensions from the file systems
    # and allows Conjur to retrieve an interface (Extension Set) for
    # calling methods on extension classes safely.
    #
    # :reek:TooManyInstanceVariables, :reek:InstanceVariableAssumption
    class Repository
      attr_reader :extensions

      # ExtensionClass is uses to store the registered extension classes
      # in a more strongly typed manner
      RegisteredExtensionClass = Struct.new(
        :kind,
        :extension_class,
        keyword_init: true
      )

      @loaded_extensions = []
      @registered_extension_classes = []

      class << self
        # This are intentionally writable to support testing
        # :reek:Attribute
        attr_accessor :loaded_extensions, :registered_extension_classes

        # :reek:LongParameterList is due to dependency injection
        def register_extension(
          extension_kind:,
          extension_class:,
          logger: Rails.logger,
          registered_extension_classes: @registered_extension_classes
        )
          logger.info(
            "Registering #{extension_kind} extension: " \
            "#{extension_class} " \
            "(#{Object.const_source_location(extension_class.name).join(':')})"
          )
          registered_extension_classes.push(
            RegisteredExtensionClass.new(
              kind: extension_kind,
              extension_class: extension_class
            )
          )
        end
      end

      # auto_load is not a control parameter for the class as a whole, but
      # only whether it tries to pre-load available Conjur extensions
      # :reek:BooleanParameter :reek:ControlParameter
      #
      # :reek:LongParameterList due to dependency injection
      def initialize(
        extensions_dir: File.join(Dir.getwd, 'extensions'),
        logger: Rails.logger,
        extensions: Rails.application.config.conjur_config.extensions,
        extension_cls: Extension,
        implementation_cls: Implementation,
        auto_load: true
      )
        @extensions_dir = extensions_dir
        @logger = logger
        @extensions = extensions
        @extension_cls = extension_cls
        @implementation_cls = implementation_cls

        return unless auto_load

        # Only attempt to load the extensions that are configured to load
        @extensions.each do |extension_name|
          load_extension(extension_name)
        end
      end

      # Load an individual extension by name from the extensions directory
      def load_extension(extension_name)
        # Check that we haven't already loaded this extension
        return false if extension_already_loaded?(extension_name)

        @logger.info("Loading extension: #{extension_name}")
        extension_path = File.join(
          @extensions_dir,
          extension_name,
          "#{extension_name}.rb"
        )

        # Check that the requested extension exists where it is expected
        return false unless extension_exist?(extension_path)

        # Load the extension source file
        @logger.debug(
          "Extension::Repository - Loading extension from '#{extension_path}'"
        )
        return false unless load(extension_path, wrap: true)

        # Record that we've loaded this extension
        self.class.loaded_extensions.push(extension_name)

        true
      end

      # returns an Extension::Extension object, used for calling extension
      # methods from Conjur application code
      def extension(kind:)
        @extension_cls.new(
          implementations: implementations_for_kind(kind),
          logger: @logger
        )
      end

      private

      # :reek:DuplicateMethodCall due to ext.extension_class, but factoring
      # that to a variable doesn't improve performance or readability
      def implementations_for_kind(kind)
        self.class.registered_extension_classes
          .select { |ext| ext.kind == kind }
          .map do |ext|
            @logger.debug(
              "Extension::Repository - Initializing extension " \
              "#{ext.extension_class.name}"
            )

            @implementation_cls.from_extension_class(
              ext.extension_class,
              # Dependencies that are injected into the extension class
              # initializers (when possible):
              logger: @logger
            )
          rescue => e
            @logger.warn(
              "Extension::Repository - Cannot initialize extension " \
              "'#{ext.extension_class.name}': #{e.message}"
            )
            nil
          end
          .compact
      end

      def extension_already_loaded?(extension_name)
        return false unless self.class.loaded_extensions.include?(extension_name)

        @logger.debug(
          "Extension::Repository - Extension " \
          "'#{extension_name}' is already loaded"
        )

        true
      end

      def extension_exist?(extension_path)
        extension_dir = File.dirname(extension_path)
        unless File.directory?(extension_dir)
          @logger.debug(
            "Extension::Repository - Expected extension " \
            "directory at '#{extension_dir}', but this path does not exist " \
            "or is not a directory"
          )

          return false
        end

        unless File.file?(extension_path)
          @logger.debug(
            "Extension::Repository - Expected extension " \
            "file at '#{extension_path}', but this path does not exist or is " \
            "not a file"
          )

          return false
        end

        # The extension directory and file exist in the extensions directory
        true
      end
    end
  end
end
