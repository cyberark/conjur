module Authentication
  module AuthnJwt

    # This  class parses complex claim path string
    # like claim1/claim2[3]/claim3[4][67]/claim6
    # to array where claim names are strings and indexes are ints
    class ParseClaimPath
      DEFAULT_PATH_SEPARATOR = "/"
      SINGLE_CLAIM_NAME_REGEX = /[a-zA-Z|$|_][a-zA-Z|$|_|0-9|.]*(\[\d+\])*/.freeze
      NESTED_CLAIM_NAME_REGEX = %r{^#{SINGLE_CLAIM_NAME_REGEX.source}(#{DEFAULT_PATH_SEPARATOR}#{SINGLE_CLAIM_NAME_REGEX.source})*$}.freeze

      def call(claim:, parts_separator: DEFAULT_PATH_SEPARATOR)
        raise Errors::Authentication::AuthnJwt::InvalidClaimPath, claim unless
          claim.match?(NESTED_CLAIM_NAME_REGEX)

        claim
          .gsub(/[\[\]]/, parts_separator)
          .split(parts_separator)
          .delete_if(&:empty?)
          .map{ |part| part =~ /^\d+$/ ? part.to_i : part }
      end
    end
  end
end
