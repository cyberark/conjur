# frozen_string_literal: true

# An exception to wrap any type of Policy processing error
# and provide additional meta data.

# The Enhanced aspect is about providing user-friendly text intended
# to aid the policy submitter in correcting the policy problem.  The
# selected attributes help identify the location of the error.  The
# original error is included to aid in identification of the original
# error.

module Exceptions
  class EnhancedPolicyError < RuntimeError

    attr_reader :original_error, :detail_message, :advice

    def initialize(original_error: nil, detail_message: '')
      super(original_error)
      @original_error = original_error
      @detail_message = if detail_message.present?
        detail_message
      else
        original_message
      end
      explainer = Commands::Policy::ExplainError.new
      @advice = explainer.call(self)
    end

    def original_message
      # Not every exception supports .message -- e.g. NoMethodError
      @original_error.respond_to?(:message) ? original_error.message : original_error.to_s
    end

    def line
      return unless original_error.respond_to?(:line)

      original_error.line
    end

    def column
      return unless original_error.respond_to?(:column)

      original_error.column
    end

    def filename
      return 'policy' unless original_error.respond_to?(:filename)

      return 'policy' if original_error.filename == '<unknown>'

      original_error.filename
    end

    def prefix
      prefix_builder = ['Error']
      if [line, column].all? { |x| x!='' && !x.nil? && x.positive? }
        prefix_builder.append("at line #{line}, column #{column}")
      end
      prefix_builder.append("in #{filename}:")
      prefix_builder.compact.join(' ')
    end

    def full_message
      # Returns a multi-line message in the form of:
      # Error at line #{line}, column #{column} in policy #{filename}:
      # #{detail_message}
      # #{advice}
      [prefix, detail_message, advice].compact.join("\n")
    end

    def enhanced_message
      # Returns a multi-line message in the form of:
      # "#{detail_message}\n#{advice}"
      [detail_message, advice].join("\n")
    end

    def to_s
      # This is the basic message, safe & suitable for any use
      detail_message
    end

    def as_json(_options = nil)
      {
        code: "policy_invalid",
        message: full_message
      }
    end

    def as_load_error
      {
        code: "policy_invalid",
        message: enhanced_message
      }
    end

    def as_validation
      {
        line: line,
        column: column,
        message: enhanced_message
      }
    end
  end
end
