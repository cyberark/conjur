# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2
      class ClaimContract < Dry::Validation::Contract
        option :authenticator

        params do
          required(:claim).value(:string)
          required(:jwt).value(:hash)
          required(:claim_value).value(:string)
        end

        def response_from_exception(error)
          { exception: error, text: error.message }
        end

        # Verify claim has a value
        rule(:claim, :claim_value) do
          if values[:claim_value].empty?
            key.failure(
              **response_from_exception(
                Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven.new(values[:claim])
              )
            )
          end
        end

        # Verify claim annotation is not in the reserved_claims list
        rule(:claim) do
          if authenticator.reserved_claims.include?(values[:claim].strip)
            key.failure(
              **response_from_exception(
                Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError.new(values[:claim])
              )
            )
          end
        end

        # Ensure claim contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/", ".")
        rule(:claim) do
          unless values[:claim].count('a-zA-Z0-9\/\-_\.') == values[:claim].length
            key.failure(
              **response_from_exception(
                Errors::Authentication::AuthnJwt::InvalidRestrictionName.new(values[:claim])
              )
            )
          end
        end

        # If claim annotation has been mapped to an alias
        rule(:claim) do
          if authenticator.claim_aliases_lookup.invert.key?(values[:claim])
            key.failure(
              **response_from_exception(
                Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError.new(
                  "Annotation Claim '#{values[:claim]}' cannot also be aliased"
                )
              )
            )
          end
        end

        # Verify target claim exists in jwt and has a value which matches the one that's provided
        rule(:claim, :jwt, :claim_value) do
          claim = authenticator.claim_aliases_lookup[values[:claim]] || values[:claim]
          resolved_value = values[:jwt].dig(*claim.split('/'))
          if resolved_value.blank?
            key.failure(
              **response_from_exception(
                Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing.new(
                  "#{claim} (annotation: #{values[:claim]})"
                )
              )
            )
          elsif resolved_value != values[:claim_value]
            key.failure(
              **response_from_exception(
                Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions.new(
                  values[:claim]
                )
              )
            )
          end
        end
      end

      class ResolveIdentity
        def initialize(authenticator:, logger: Rails.logger)
          @authenticator = authenticator
          @logger = logger
        end

        # Identifier is a hash representation of a JWT
        def call(identifier:, allowed_roles:, id: nil)
          # jwt = identifier

          role_identifier = identifier(id: id, jwt: identifier)

          allowed_roles.each do |role|
            next unless match?(identifier: role_identifier, role: role)

            are_role_annotations_valid?(
              role: role,
              jwt: identifier
            )

            return role[:role_id]
          end

          # If there's an id provided, this is likely a user
          if id.present?
            raise(Errors::Authentication::Security::RoleNotFound, role_identifier)
          end

          # Otherwise, raise error with the assumed intended target:
          raise(Errors::Authentication::Security::RoleNotFound, "host/#{role_identifier}")
        end

        private

        def match?(identifier:, role:)
          # If provided identity is a host, it'll starty with "host/". We need to match
          # on the type as well as acount and role id.
          if identifier.match(%r{^host\/})
            role_account, role_type, role_id = role[:role_id].split(':')
            host_identity = identifier.gsub(%r{^host\/}, '')
            role_account == @authenticator.account && host_identity == role_id && role_type == 'host'
          else
            role_account, _, role_id = role[:role_id].split(':')
            role_account == @authenticator.account && identifier == role_id
          end
        end

        # accepts hash of role annotations
        # merges generic and specific authn-jwt annotations, prioritizing specific
        # returns
        # {
        #   'claim-1' => 'claim 1 value',
        #   'claim-2' => 'claim 2 value'
        # }
        def relevant_annotations(annotations)
          generic   = {}
          specific  = {}
          annotations.each do |key, value|
            next unless key.match(%r{^authn-jwt/})

            parts = key.split('/')
            if parts.length == 2 && parts.last != @authenticator.service_id
              generic[parts.last] = value
            elsif parts.length == 3 && parts[1] == @authenticator.service_id
              specific[parts.last] = value
            end
          end

          # binding.pry
          if specific.empty? # generic.empty? ||
            raise Errors::Authentication::Constraints::RoleMissingAnyRestrictions
          end

          generic.merge(specific)
        end

        def verify_enforced_claims(authenticator_annotations)
          # Resolve any aliases
          role_claims = authenticator_annotations.keys.map { |annotation| @authenticator.claim_aliases_lookup[annotation] || annotation }

          # Find any enforced claims not present
          missing_claims = (@authenticator.enforced_claims - role_claims)

          return if missing_claims.count.zero?

          raise Errors::Authentication::Constraints::RoleMissingConstraints, missing_claims
        end

        def are_role_annotations_valid?(role:, jwt:)
          authenticator_annotations = relevant_annotations(role[:annotations])

          # # Gather Authenticator specific annotations
          # authenticator_annotations = role[:annotations].select { |k, _| k.match(%r{^authn-jwt/}) }

          # At least one relevant annotation is required
          # if authenticator_annotations.empty?
          #   raise Errors::Authentication::Constraints::RoleMissingAnyRestrictions
          # end

          # service_id_annotations = authenticator_annotations
          #   .select { |k, _| k.match(%r{^authn-jwt/#{@authenticator.service_id}/}) }

          # if service_id_annotations.empty?
          #   raise Errors::Authentication::Constraints::RoleMissingAnyRestrictions
          # end

          # Validate that defined enforced claims are present
          verify_enforced_claims(authenticator_annotations) if @authenticator.enforced_claims.any?
            # Gather relevant host annotations and handle any aliases
            # host_claims = service_id_annotations
            #   .map { |k, _| k.gsub(%r{^authn-jwt/#{@authenticator.service_id}/}, '')}
            #   .map { |a| @authenticator.claim_aliases_lookup[a] || a }

            #
            # host_claims = authenticator_annotations.keys.map { |annotation| @authenticator.claim_aliases_lookup[annotation] || annotation }

          #   # At this point we have a list of JWT claims based on host annotations and host annotation aliasing
          #   missing_required_claims = (@authenticator.enforced_claims - host_claims)

          #   if missing_required_claims.count.positive?
          #     raise Errors::Authentication::Constraints::RoleMissingConstraints, missing_required_claims
          #   end
          # end

          # Verify all claims are the same
          authenticator_annotations.each do |claim, value|
            validate_claim!(claim: claim, value: value, jwt: jwt)
          end

          # # Ensure service specific annotations match
          # service_id_annotations.each do |key, value| #|service_id_annotation|
          #   # move to hash lookup
          #   claim = key.gsub(%r{^authn-jwt/#{@authenticator.service_id}/}, '')
          #   validate_claim!(claim: claim, value: value, identifier: identifier)
          # end

          # # Ensure general restrictions match
          # authenticator_annotations.reject { |k,_| service_id_annotations.key?(k) }.each do |key, value|
          #   # ignore invalid service ID annotations (ex. authn-jwt/<service-id>:)
          #   next if key == "authn-jwt/#{@authenticator.service_id}"

          #   # ignore annotations for different service IDs
          #   next if key.split('/').length > 2

          #   claim = key.gsub(%r{^authn-jwt/}, '')
          #   validate_claim!(claim: claim, value: value, identifier: identifier)
          # end

          # I suspect this error message isn't suppose to be written in the past tense....
          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictions.new)
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidateRestrictionsPassed.new)
        end

        # def identity_from_token_app_property(jwt:) #, token_app_property:, identity_path:)
        def retrieve_identity_from_jwt(jwt:)
          # Handle nested claim lookups
          identity = jwt.dig(*@authenticator.token_app_property.split('/'))

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
          # Make sure we allow flexibility for optionally included trailing slash on identity_path
          (@authenticator.identity_path.to_s.split('/').compact << identity).join('/')
        end

        def identifier(id:, jwt:)
          # User ID should only be present without `token-app-property` because
          # we'll use the id to lookup the host/user
          if id.present? && @authenticator.token_app_property.present?
            raise Errors::Authentication::AuthnJwt::IdentityMisconfigured
          end

          # NOTE: `token_app_property` maps the specified jwt claim to a host of the
          # same name.
          if @authenticator.token_app_property.present?
            retrieve_identity_from_jwt(jwt: jwt) #, token_app_property: @authenticator.token_app_property, identity_path: @authenticator.identity_path)
          elsif id.present?
            id
          else
            raise Errors::Authentication::AuthnJwt::IdentityMisconfigured
          end
        end

        def validate_claim!(claim:, value:, jwt:)
          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionOnRequest.new(claim))

          claim_valid = ClaimContract.new(authenticator: @authenticator).call(
            claim: claim,
            jwt: jwt,
            claim_value: value
          )

          unless claim_valid.success?
            @logger.info(claim_valid.errors.to_h.inspect)
            # binding.pry
            # If contract fails, raise the first defined exception...
            raise(claim_valid.errors.first.meta[:exception])
          end

          # # Verify claim annotation is not in the reserved_claims list
          # if @authenticator.reserved_claims.include?(claim)
          #   raise Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError, claim
          # end

          # # Verify claim has a value
          # if value.empty?
          #   raise Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven, claim
          # end

          # # Ensure claim contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/", ".")
          # unless claim.count('a-zA-Z0-9\/\-_\.') == claim.length
          #   raise Errors::Authentication::AuthnJwt::InvalidRestrictionName, claim
          # end

          # if @authenticator.claim_aliases.present?

            # # If claim annotation has been mapped to an alias
            # if @authenticator.claim_aliases_lookup.invert.key?(claim)
            #   raise Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError,
            #         "Annotation Claim '#{claim}' cannot also be aliased"
            # end

            # # If aliased, lookup the claim value using aliased the claim
            # if @authenticator.claim_aliases_lookup.key?(claim)
            #   aliased_claim = @authenticator.claim_aliases_lookup[claim]

            #   # unless jwt.dig(*aliased_claim.split('/')).present?
            #   #   raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing,
            #   #     "#{aliased_claim} (annotation: #{claim})"
            #   # end

            # # If the alias isn't in the claim alias, use the provided claim
            # else
            #   aliased_claim = claim
            # end

            # identity_value = jwt.dig(*aliased_claim.split('/'))
          # else
          #   identity_value = jwt.dig(*claim.split('/'))
          # end

          # if identity_value.blank?
          #   raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing, claim
          # end

          # unless identity_value == value
          #   raise Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions, claim
          # end

          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsValues.new(claim))
        end
      end
    end
  end
end
