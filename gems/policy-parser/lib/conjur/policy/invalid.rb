module Conjur
  module PolicyParser

    class Invalid < RuntimeError
      attr_reader :message, :filename, :detail_message, :line, :column

      def initialize(message:, filename:, line: -1, column: -1)
        super(
          "Error at line #{line}, column #{column} in " \
            "#{filename} : #{message}"
        )
        @filename = filename
        @line = line
        @column = column
        @detail_message = message
      end
    end

    class ResolverError < RuntimeError
      attr_reader :original_error, :detail_message

      def initialize(original_error:)
        super(original_error.message)
        @original_error = original_error
        @detail_message = original_error.message
      end
    end

  end
end
