# frozen_string_literal: true

require 'yaml'
require 'psych'

module EffectivePolicy
  module PolicyTree
    module Tagging
      def tag(kind, value)
        Tag.new(kind.to_s.tr('_', '-'), value)
      end

      def pure_str_tag(value)
        PureStringTag.new(value)
      end
    end

    class Tag
      # Basic building part of policy tree that will be formatted to a policy statement.
      # Method 'encode_with' is used by psych and allows to customize the output.
      # When only id is provided as the value a shortcut version of statement is generated, e.g.:
      #  - !policy acme-root
      #  - !user ali
      # In case of the hash as value, normal version of statement is generated:
      #  - !policy
      #   id: subpolicy4
      #   body:
      #    ...
      attr_reader :kind
      attr_accessor :value

      def initialize(kind, value = nil)
        @kind = kind
        @value = value
      end

      def to_s
        "{kind = #{@kind}, value = #{@value}}"
      end

      def encode_with(coder)
        coder.tag = "!#{kind}"

        return unless !!value

        if kind == 'policy' && value.is_a?(Hash)
          value["body"] = sort_body
        end

        case value
        when Hash
          if value.one?
            coder.scalar = value["id"]
          else
            coder.map = value
          end
        when Array
          coder.seq = value
        else
          coder.scalar = value.to_s
        end
      end

      def as_json(options = {})
        { kind => value }
      end

      def sort_body
        value["body"].sort_by { |k, _| BODY_SORT_ORDER[k.kind] }
      end

      BODY_SORT_ORDER = { "user" => 1, "policy" => 2, "variable" => 3, "webservice" => 4, "host" => 5,
                          "layer" => 6, "host-factory" => 7, "group" => 8, "grant" => 9,
                          "permit" => 10 }.freeze
    end

    class PureStringTag
      # Used for displaying an array as string conjur way e.g.:
      # [foo, bar, baz]
      # Method 'encode_with' is used by psych and allows to customize the output.
      # It uses FLOW style from psych
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def as_json(options = {})
        value
      end

      def to_s
        "{value = #{@value}}"
      end

      def encode_with(coder)
        coder.style = Psych::Nodes::Mapping::FLOW
        coder.tag = nil

        return unless !!value

        case value
        when Hash
          coder.map = value
        when Array
          coder.seq = value
        else
          coder.scalar = value.to_s
        end
      end
    end
  end
end
