# frozen_string_literal: true

# A simple factory for creating custom RuntimeError classes without
# the typical boilerplate
#
module Util

  class ErrorClass
    def self.new(msg)
      Class.new(RuntimeError) do
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
