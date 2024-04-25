# frozen_string_literal: true

# Provides a user-friendly explanation for parse errors

module Commands
  module Policy

    HELPFUL_EXPLANATIONS = {
      'Unexpected scalar' => 'Please check the syntax for defining a new node.',
    }

    class ExplainError

      def call(parse_error: nil)
          HELPFUL_EXPLANATIONS[ "#{parse_error}" ]
      end

    end
  end
end
