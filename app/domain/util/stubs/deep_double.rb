module Util
  module Stubs
    class DeepDouble

      class LookupReturnValue
        def initialize(meth, spec, args)
          @spec = spec
          @meth = meth
          @raw_args = args
        end

        def call
          validate_method_exists
          validate_args_are_defined
          found_value
        end

        private

        def validate_method_exists
          return if @spec.key?(@meth)
          raise "Method '#{@meth}' not defined on this double"
        end

        def validate_args_are_defined
          return if args_defined?
          raise "Return value on '#{@meth}' undefined for args: #{args}"
        end

        def found_value
          return recursive(stubbed_vals) unless args
          recursive(stubbed_vals[args])
        end

        def recursive(val)
          val.is_a?(Hash) ? DeepDouble.new(val) : val
        end

        def stubbed_vals
          @spec[@meth]
        end

        def args_defined?
          @raw_args.empty? ? true : stubbed_vals.key?(args)
        end

        def num_args
          @raw_args.size
        end

        def args
          case
          when num_args >  1 then @raw_args 
          when num_args == 1 then @raw_args.first
          else nil
          end
        end
      end

      def initialize(name = 'Double', spec)
        @name = name
        @spec = spec
      end

      def method_missing(meth, *args)
        LookupReturnValue.new(meth, @spec, args).call
      end
    end
  end
end
