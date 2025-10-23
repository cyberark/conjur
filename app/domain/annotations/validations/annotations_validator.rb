# frozen_string_literal: true

module Annotations
  module Validations
    ANNOTATION_PATTERN = /\A[^<>']+\Z/.freeze
    ANNOTATION_LENGTH_MIN = 1
    ANNOTATION_LENGTH_MAX = 120

    class AnnotationsValidator < ActiveModel::Validator
      def validate(annotations)
        annotations.each do |key, value|
          key_s = key.to_s
          annotations.errors.add(key_s, "annotation key format error '#{key_s}'") unless ANNOTATION_PATTERN.match?(key_s)
          annotations.errors.add(key_s, "annotation key length cannot exceeded #{ANNOTATION_LENGTH_MIN}") unless key_s.length >= ANNOTATION_LENGTH_MIN
          annotations.errors.add(key_s, "annotation key length cannot exceeded #{ANNOTATION_LENGTH_MAX}") unless key_s.length <= ANNOTATION_LENGTH_MAX

          if value.is_a?(String)
            annotations.errors.add(key, "annotation value format error") unless ANNOTATION_PATTERN.match?(value)
            annotations.errors.add(key, "annotation value length cannot exceeded #{ANNOTATION_LENGTH_MIN}") unless value.length >= ANNOTATION_LENGTH_MIN
            annotations.errors.add(key, "annotation value length cannot exceeded #{ANNOTATION_LENGTH_MAX}") unless value.length <= ANNOTATION_LENGTH_MAX
          else
            annotations.errors.add(key, "should have string value but got #{value}")
          end
        end
      end
    end
  end
end
