# frozen_string_literal: true

# A factory for creating a LogMessage
#
module Util
  class LogMessageClass
    def self.new(msg)
      Class.new do
        def initialize(*args)
          @args = args
        end
        define_method(:to_s) do
          @args.each_with_index.reduce(msg) do |m, (x, arg_index)|
            x_stringified = x.nil? ? 'nil' : x.to_s
            m.gsub(Regexp.new("\\{#{arg_index}-?[a-zA-Z-]*}"), x_stringified)
          end
        end
      end
    end
  end
end
