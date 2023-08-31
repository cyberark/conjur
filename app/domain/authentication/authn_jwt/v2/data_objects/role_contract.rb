

module Authentication
  module AuthnJwt
    module V2
      module DataObjects

        # Contract for validating role claim mapping
        class RoleContract < Dry::Validation::Contract
          option :authenticator
          option :utils

          params do
            required(:annotation).value(:string)
            required(:annotation_value).value(:string)
            required(:annotations).value(:hash)
          end

          # Verify annotation has a value
          rule(:annotation, :annotation_value) do
            if values[:annotation_value].empty?
              utils.failed_response(
                key: key,
                error: Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven.new(values[:annotation])
              )
            end
          end

          # Verify annotation value is not in the reserved_claims list
          rule(:annotation) do
            if authenticator.reserved_claims.include?(values[:annotation].strip)
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError.new(values[:annotation])
              )
            end
          end

          # Ensure annotation contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/", ".")
          rule(:annotation) do
            unless values[:annotation].count('a-zA-Z0-9\/\-_\.') == values[:annotation].length
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::InvalidRestrictionName.new(values[:annotation])
              )
            end
          end

          # If annotation has been mapped to an alias
          rule(:annotation) do
            if authenticator.claim_aliases_lookup.invert.key?(values[:annotation])
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError.new(
                  "Annotation Claim '#{values[:annotation]}' cannot also be aliased"
                )
              )
            end
          end

          # Verify all enforced claims are present on the annotations:
          rule(:annotations) do
            missing_annotations = authenticator.aliased_enforced_claims - values[:annotations].keys
            unless missing_annotations.empty?
              utils.failed_response(
                key: key,
                error: Errors::Authentication::Constraints::RoleMissingConstraints.new(
                  missing_annotations.join(', ')
                )
              )
            end
          end
        end
      end
    end
  end
end
