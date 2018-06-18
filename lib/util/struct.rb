require 'ostruct'

# Assorted utilities
module Util
  # An OpenStruct with explicitly defined initial fields.
  class Struct < OpenStruct
    def initialize values = {}
      klass = self.class
      klass.check_args values
      super klass.defaults.merge values
    end

    class << self
      def check_args values
        keys = values.keys
        if (extra = keys - fields - defaults.keys).any? # rubocop:disable Style/GuardClause
          raise ArgumentError, "unexpected parameters: #{extra.join(', ')}"
        elsif (missing = fields - keys).any?
          raise ArgumentError, "missing parameters: #{missing.join(', ')}"
        end
      end

      # Declare required and optional fields.
      # Example usage:
      #   fields :required, optional: "default"
      def field *reqfields, **optfields
        defaults.merge! optfields
        fields.push(*reqfields)
      end

      # Declare abstract fields, ie. fields which can be easily defined in a subclass.
      #
      # For example, given
      #   class Foo < Util::Struct
      #     abstract_field :id, :time
      #   end
      # You can use either a value or a proc, for example:
      #   class Bar < Foo
      #     id "bar_id"
      #     time { Time.now }
      #   end
      # Note you can still use ordinary `def` in the subclass to define the field.
      def abstract_field *fields
        fields.each(&method(:define_abstract_field))
      end

      def fields
        @fields ||= superclass.fields.dup
      end

      def defaults
        @defaults ||= superclass.defaults.dup
      end

      private

      def define_abstract_field field
        define_singleton_method(field) do |value = nil, &block|
          return super() unless value || block
          block = -> { value } if value
          define_method field, &block
        end
      end
    end

    # Base values of these properties for Util::Struct,
    # so .fields and .defaults methods can be simpler
    @fields = []
    @defaults = {}
  end
end
