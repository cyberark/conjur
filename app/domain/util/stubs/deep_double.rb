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
          val = args ? stubbed_vals[args] : stubbed_vals
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
          if num_args >  1
            @raw_args
          elsif num_args == 1
            @raw_args.first
          end
        end
      end

      # In this case, having an optional name first makes for a cleaner API
      #
      # rubocop:disable OptionalArguments
      def initialize(name = 'Double', spec)
        @name = name
        @spec = spec
        create_methods_defined_in_spec
      end
      # rubocop:enable OptionalArguments

      def create_methods_defined_in_spec
        @spec.keys.each { |meth| create_method(meth) }
      end

      def create_method(meth)
        define_singleton_method(meth.to_sym) do |*args|
          LookupReturnValue.new(meth, @spec, args).call
        end
      end

    end
  end
end
