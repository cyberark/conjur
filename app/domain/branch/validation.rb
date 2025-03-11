# frozen_string_literal: true

module Domain
  module Validation
    ANNOTATION_PATTERN = %r{\A[^<>']+\Z}.freeze
    ANNOTATION_LENGTH_MIN = 1
    ANNOTATION_LENGTH_MAX = 120

    NAME_LENGTH_MIN = 1
    NAME_LENGTH_MAX = 60
    NAME_PATTERN = %r{\A[A-Za-z0-9\-_]+}.freeze
    NAME_PATTERN_MSG = "Wrong name '%{value}'"

    PATH_LENGTH_MIN = 1
    PATH_LENGTH_MAX = 500
    PATH_PATTERN = %r{\A[A-Za-z0-9\-_/]+}.freeze

    PATH_PATTERN_MSG = "Wrong path '%{value}'"
    OWNER_KINDS = %w[host user group policy].freeze
    OWNER_KINDS_MSG = "'%{value}' is not a valid owner kind"

    class DomainValidationError < RuntimeError
    end

    class AnnotationsValidator < ActiveModel::Validator
      def validate(annotations)
        annotations.each do |key, value|
          key_s = key.to_s
          annotations.errors.add(key_s, "annotation key format error '#{key_s}'") unless ANNOTATION_PATTERN.match?(key_s)
          annotations.errors.add(key_s, "annotation key length cannot exceeded #{ANNOTATION_LENGTH_MAX}") unless key_s.length <= ANNOTATION_LENGTH_MAX
          annotations.errors.add(key_s, "annotation key length cannot exceeded #{ANNOTATION_LENGTH_MAX}") unless key_s.length <= ANNOTATION_LENGTH_MAX

          if value.is_a?(String)
            annotations.errors.add(key, "annotation value format error") unless ANNOTATION_PATTERN.match?(value)
            annotations.errors.add(key, "annotation value length cannot exceeded #{ANNOTATION_LENGTH_MAX}") unless value.length <= ANNOTATION_LENGTH_MAX
            annotations.errors.add(key, "annotation value length cannot exceeded #{ANNOTATION_LENGTH_MAX}") unless value.length <= ANNOTATION_LENGTH_MAX
          else
            annotations.errors.add(key, "should have string value but got #{value}")
          end
        end
      end
    end
  end
end
