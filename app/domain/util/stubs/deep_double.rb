# This is a utility class for quickly and declaratively creating doubles
# of arbitrarily nested depth.
#
# It drastically reduces the amount of boilerplate in comparison to rspec.
#
# I (Jonah) plan to pull this out into a gem soon.

require_relative 'deep_double/lookup_return_value'

module Util
  module Stubs
    class DeepDouble
      # In this case, having an optional name first makes for a cleaner API
      #
      # rubocop:disable Style/OptionalArguments
      def initialize(name = 'Double', spec)
        @name = name
        @spec = spec
        create_methods_defined_in_spec
      end
      # rubocop:enable Style/OptionalArguments

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
