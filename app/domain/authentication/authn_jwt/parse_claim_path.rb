module Authentication
  module AuthnJwt

    # This class parses complex claim path string
    # like claim1/claim2[3]/claim3[4][67]/claim6
    # to array where claim names are strings and indexes are ints
    class ParseClaimPath
      def call(claim:, parts_separator: PATH_DELIMITER)
        raise Errors::Authentication::AuthnJwt::InvalidClaimPath.new(claim, INDEXED_NESTED_CLAIM_NAME_REGEX) if
          claim.nil? || !claim.match?(INDEXED_NESTED_CLAIM_NAME_REGEX)

        claim
          .gsub(/[\[\]]/, parts_separator)
          .split(parts_separator)
          .delete_if(&:empty?)
          .map{ |part| part =~ /^\d+$/ ? part.to_i : part }
      end
    end
  end
end
