module Conjur
  module PolicyParser
    class Invalid < RuntimeError
      attr_reader :filename, :mark
      
      def initialize message, filename, mark
        super(
          "Error at line #{mark.line}, column #{mark.column} in " \
            "#{filename} : #{message}"
        )
        @filename = filename
        @mark = mark
      end
    end
  end
end
