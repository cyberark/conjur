require 'app/domain/util/submodules'

module Conjur
  class ExtensionRepository
    attr_reader :extensions

    # ExtensionSet represents the Conjur interface to call extension points
    class ExtensionSet
      def initialize(
        extension_module:,
        logger: Rails.logger
      )
        @extension_module = extension_module
        @logger = logger

        @extension_classes = ::Util::Submodules.of(@extension_module)
        @logger.debug(
          "ExtensionSet#initialize - Loaded #{@extension_module.name} " \
          "extensions: #{@extension_classes.map(&:name).join(', ')}"
        )
      end

      def call(method, **kwargs)
        @logger.debug(
          "ExtensionSet#call - Calling #{method} on " \
          "#{@extension_module.name} extensions"
        )

        extensions.each do |extension|
          unless extension.respond_to?(method)
            @logger.debug(
              "ExtensionSet#call - #{extension.class.name} doesn't respond " \
              "to #{method}"
            )
            next
          end

          @logger.debug(
            "ExtensionSet#call - Calling #{method} on #{extension.class.name}"
          )
          begin
            extension.send(method, **kwargs)
          rescue => e
            # Failed extension calls do not bubble up exceptions. They are
            # logged, but otherwise ignored by Conjur. Exceptions in extensions
            # should be fully handled in the extension implementation itself.
            @logger.error(
              "ExtensionSet#call - Failed to call #{method} on " \
              "#{extension.class.name}: #{e.message}"
            )
          end
        end
      end

      private

      def extensions
        @extensions ||= @extension_classes.map do |extension_class|
          @logger.debug(
            "ExtensionRepository#extensions - Initializing extension " \
            "#{extension_class.name}"
          )

          extension_class.new(
            # These are dependencies the extension may use in its
            # implementation. At a minimum, extenszion initializers must include
            # a **kwargs initializer argument to consume any arguments it
            # doesn't declare specifically.
            logger: @logger
          )
        end
      end
    end

    @installed_extensions = []

    def initialize(
      root_dir: Dir.getwd,
      logger: Rails.logger
    )
      @root_dir = root_dir
      @logger = logger

      # We can't hot-reload extensions, so we only need to do this once per
      # Ruby runtime.
      @installed_extensions ||= require_extensions
    end

    def get(extension_module)
      ExtensionSet.new(
        extension_module: extension_module,
        logger: @logger
      )
    end

    private

    def require_extensions
      extensions_dir = File.join(@root_dir, 'extensions')

      unless File.directory?(extensions_dir)
        @logger.debug(
          "ExtensionRepository#require_extensions - '#{extensions_dir}' is " \
          "not a directory"
        )
        return
      end

      Dir.children(extensions_dir).map do |extension_name|
        extension_dir = File.join(extensions_dir, extension_name)

        unless File.directory?(extension_dir)
          @logger.debug(
            "ExtensionRepository#require_extensions - '#{extension_dir}' is " \
            "not a directory"
          )
          next
        end

        extension_path = File.join(extension_dir, "#{extension_name}.rb")

        unless File.file?(extension_path)
          @logger.debug(
            "ExtensionRepository#require_extensions - '#{extension_path}' is " \
            "not a file"
          )
          next
        end

        @logger.debug(
          "ExtensionRepository#require_extensions - Requiring " \
          "'#{extension_path}'"
        )
        require(extension_path)

        extension_name
      end.compact
    end
  end
end
