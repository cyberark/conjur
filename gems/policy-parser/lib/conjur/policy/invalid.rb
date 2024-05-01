module Conjur
  module PolicyParser
    class Invalid < RuntimeError
      attr_reader :filename, :mark, :detail_message
      
      def initialize message, filename, mark
        super(
          "Error at line #{mark.line}, column #{mark.column} in " \
            "#{filename} : #{message}"
        )
        @filename = filename
        @mark = mark
        @detail_message = message
      end
    end
  end
end
