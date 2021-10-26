
module Authentication
  module AuthnJwt

    # This  class parses complex claim path string
    # like claim1/claim2[3]/claim3[4][67]/claim6
    # to array where claim names are strings and indexes are ints
    class ParseClaimPath
      def call(claim:, parts_separator: '/')

        raise Errors::Authentication::AuthnJwt::InvalidClaimPath.new(claim) unless
          claim.match?(NESTED_CLAIM_NAME_REGEX)

        parts = []

        claim
          .gsub(/[\[\]]/, parts_separator)
          .split(parts_separator)
          .delete_if(&:empty?)
          .each do | part |
          if part.match(/^\d+$/)
            parts.append(part.to_i)
          else
            parts.append(part)
          end
        end

        parts
      end
    end
  end
end
