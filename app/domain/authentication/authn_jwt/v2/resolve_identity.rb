# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2
      class ResolveIdentity

        def initialize(authenticator:, logger: Rails.logger)
          @authenticator = authenticator
          @logger = logger
        end

        def call(identifier:, account:, allowed_roles:, id: nil)
          # User ID should only be present without `token-app-property` because
          # we'll use the id to lookup the host/user
          if id.present? && @authenticator.token_app_property.present?
            raise Errors::Authentication::AuthnJwt::IdentityMisconfigured
          end

          # NOTE: `token_app_property` maps the specified jwt claim to a host of the
          # same name.
          if @authenticator.token_app_property.present?
            # Handle nested claim lookups
            identity = identifier.dig(*@authenticator.token_app_property.split('/'))

            unless identity.present?
              raise(Errors::Authentication::AuthnJwt::NoSuchFieldInToken, @authenticator.token_app_property)
            end

            unless identity.is_a?(String)
              raise Errors::Authentication::AuthnJwt::TokenAppPropertyValueIsNotString.new(
                @authenticator.token_app_property,
                identity.class
              )
            end

            # If identity path is present, prefix it to the identity
            if @authenticator.identity_path.present?
              identity = [@authenticator.identity_path, identity].join('')
            end
          elsif id.present?
            identity = id
          else
            raise Errors::Authentication::AuthnJwt::IdentityMisconfigured
          end

          allowed_roles.each do |role|
            # If provided identity is a host, it'll starty with "host/". We need to match
            # on the type as well as acount and role id.
            if identity.match(/^host\//)
              role_account, role_type, role_id = role.id.split(':')
              identity = identity.gsub(/^host\//, '')
              next unless role_account == account && identity == role_id && role_type == 'host'
            else
              role_account, _, role_id = role.id.split(':')
              next unless role_account == account && identity == role_id
            end

            # Gather Authenticator specific annotations
            authenticator_annotations = role.resource.annotations.select { |a| a.name.match(/^authn-jwt\//) }

            # At least one relevant annotation is required
            if authenticator_annotations.empty?
              raise Errors::Authentication::Constraints::RoleMissingAnyRestrictions
            end

            service_id_annotations = authenticator_annotations
              .select { |a| a.name.match(/^authn-jwt\/#{@authenticator.service_id}\//) }

            # Validate that defined enforced claims are present
            if @authenticator.enforced_claims.any?

              # Gather relevant host annotations
              host_claims = service_id_annotations.map { |a| a.name.gsub(/^authn-jwt\/#{@authenticator.service_id}\//, '')}

              # Gather and handle any aliases
              host_claims = host_claims.map { |a| @authenticator.claim_aliases_lookup[a] || a }

              # At this point we have a list of JWT claims based on host annotations and host annotation aliasing
              missing_required_claims = (@authenticator.enforced_claims - host_claims)

              if missing_required_claims.count.positive?
                raise Errors::Authentication::Constraints::RoleMissingConstraints, missing_required_claims
              end
            end

            if service_id_annotations.empty?
              raise Errors::Authentication::Constraints::RoleMissingAnyRestrictions
            end

            # Ensure service specific annotations match
            service_id_annotations.each do |service_id_annotation|
              claim = service_id_annotation.name.gsub(/^authn-jwt\/#{@authenticator.service_id}\//, '')
              validate_claim!(claim: claim, value: service_id_annotation.value, identifier: identifier)
            end

            # Ensure general restrictions match
            (authenticator_annotations - service_id_annotations).each do |authenticator_annotation|
              # ignore invalid service ID annotations (ex. authn-jwt/<service-id>:)
              next if authenticator_annotation.name == "authn-jwt/#{@authenticator.service_id}"

              # ignore annotations for differen service IDs
              next if authenticator_annotation.name.split('/').length > 2

              claim = authenticator_annotation.name.gsub(/^authn-jwt\//, '')
              validate_claim!(claim: claim, value: authenticator_annotation.value, identifier: identifier)
            end

            # I suspect this error message isn't suppose to be written in the past tense....
            @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictions.new)
            @logger.debug(LogMessages::Authentication::AuthnJwt::ValidateRestrictionsPassed.new)

            return role
          end

          # If there's an id provided, this is likely a user
          if id.present?
            raise(Errors::Authentication::Security::RoleNotFound, identity)
          end

          # Otherwise, raise error with the assumed intended target:
          raise(Errors::Authentication::Security::RoleNotFound, "host/#{identity}")
        end

        def validate_claim!(claim:, value:, identifier:)
          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionOnRequest.new(claim))

          # Verify claim annotation is not in the reserved_claims list
          if @authenticator.reserved_claims.include?(claim)
            raise Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError, claim
          end

          # Verify claim has a value
          if value.empty?
            raise Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven, claim
          end

          # Ensure claim contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/", ".")
          unless claim.count('a-zA-Z0-9\/\-_\.') == claim.length
            raise Errors::Authentication::AuthnJwt::InvalidRestrictionName, claim
          end

          if @authenticator.claim_aliases.present?

            # If claim annotation has been mapped to an alias
            if @authenticator.claim_aliases_lookup.invert.key?(claim)
              raise Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError,
                    "Annotation Claim '#{claim}' cannot also be aliased"
            end

            # If aliased, lookup the claim value using aliased the claim
            if @authenticator.claim_aliases_lookup.key?(claim)
              aliased_claim = @authenticator.claim_aliases_lookup[claim]

              unless identifier.dig(*aliased_claim.split('/')).present?
                raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing,
                  "#{aliased_claim} (annotation: #{claim})"
              end

            # If the alias isn't in the claim alias, use the provided claim
            else
              aliased_claim = claim
            end

            identity_value = identifier.dig(*aliased_claim.split('/'))
          else
            identity_value = identifier.dig(*claim.split('/'))
          end

          if identity_value.blank?
            raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing, claim
          end

          unless identity_value == value
            raise Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions, claim
          end

          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsValues.new(claim))
        end
      end
    end
  end
end
