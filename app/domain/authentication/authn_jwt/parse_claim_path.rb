module Authentication
  module AuthnJwt

    # This class parses complex claim path string
    # like claim1/claim2/claim3/claim6
    # to array where claim names are strings and indexes are ints
    class ParseClaimPath
      def call(claim:, parts_separator: PATH_DELIMITER)
        raise Errors::Authentication::AuthnJwt::InvalidClaimPath.new(claim, PURE_NESTED_CLAIM_NAME_REGEX) if
          claim.nil? || !claim.match?(PURE_NESTED_CLAIM_NAME_REGEX)

        claim
          .split(parts_separator)
      end
    end
  end
end
