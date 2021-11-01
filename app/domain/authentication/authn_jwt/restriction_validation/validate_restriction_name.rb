require 'command_class'

module Authentication
  module AuthnJwt
    module RestrictionValidation
      # Class to validate host annotation name is according the format of nested claim in JWT
      class ValidateRestrictionName
        def call(restriction:)
          restriction_name = restriction.name
          if restriction_name.empty? || !restriction_name.match?(PURE_NESTED_CLAIM_NAME_REGEX)
            raise Errors::Authentication::AuthnJwt::InvalidRestrictionName, restriction_name
          end
        end
      end
    end
  end
end
