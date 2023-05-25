# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2

      # Contract for validating role claim mapping
      class ClaimContract < Dry::Validation::Contract
        option :authenticator
        option :utils

        params do
          required(:claim).value(:string)
          required(:jwt).value(:hash)
          required(:claim_value).value(:string)
        end

        # Verify claim has a value
        rule(:claim, :claim_value) do
          if values[:claim_value].empty?
            utils.failed_response(
              key: key,
              error: Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven.new(values[:claim])
            )
          end
        end

        # Verify claim annotation is not in the reserved_claims list
        rule(:claim) do
          if authenticator.reserved_claims.include?(values[:claim].strip)
            utils.failed_response(
              key: key,
              error: Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError.new(values[:claim])
            )
          end
        end

        # Ensure claim contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/", ".")
        rule(:claim) do
          unless values[:claim].count('a-zA-Z0-9\/\-_\.') == values[:claim].length
            utils.failed_response(
              key: key,
              error: Errors::Authentication::AuthnJwt::InvalidRestrictionName.new(values[:claim])
            )
          end
        end

        # If claim annotation has been mapped to an alias
        rule(:claim) do
          if authenticator.claim_aliases_lookup.invert.key?(values[:claim])
            utils.failed_response(
              key: key,
              error: Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError.new(
                "Annotation Claim '#{values[:claim]}' cannot also be aliased"
              )
            )
          end
        end

        # Verify target claim exists in jwt
        rule(:claim, :jwt, :claim_value) do
          value, resolved_claim = claim_value_from_jwt(claim: values[:claim], jwt: values[:jwt], return_resolved_claim: true)
          if value.blank?
            utils.failed_response(
              key: key,
              error: Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing.new(
                "#{resolved_claim} (annotation: #{values[:claim]})"
              )
            )
          end
        end

        # Verify claim has a value which matches the one that's provided
        rule(:claim, :jwt, :claim_value) do
          if claim_value_from_jwt(claim: values[:claim], jwt: values[:jwt]) != values[:claim_value]
            utils.failed_response(
              key: key,
              error: Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions.new(
                values[:claim]
              )
            )
          end
        end

        # return_resolved_claim arguement is here to allow us to return the resolved claim for the
        # above rule which includes it in the error message
        def claim_value_from_jwt(jwt:, claim:, return_resolved_claim: false)
          resolved_claim = authenticator.claim_aliases_lookup[claim] || claim
          value = jwt.dig(*resolved_claim.split('/'))

          return_resolved_claim ? [value, resolved_claim] : value
        end
      end

      class ResolveIdentity
        def initialize(authenticator:, logger: Rails.logger)
          @authenticator = authenticator
          @logger = logger
        end

        # Identifier is a hash representation of a JWT
        def call(identifier:, allowed_roles:, id: nil)
          role_identifier = identifier(id: id, jwt: identifier)
          # binding.pry
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

          role_identifier = identifier
          role_account, role_type, role_id = role[:role_id].split(':')
          target_type = role_type

          if identifier.match(%r{^host/})
            target_type = 'host'
            role_identifier = identifier.gsub(%r{^host/}, '')
          end

          role_account == @authenticator.account && role_identifier == role_id && role_type == target_type
        end

        def filtered_annotation_as_hash(annotations:, regex:)
          annotations.select { |annotation, _| annotation.match?(regex) }
            .transform_keys { |annotation| annotation.match(regex)[1] }
        end

        # accepts hash of role annotations
        #
        # merges generic and specific authn-jwt annotations, prioritizing specific
        # returns
        # {
        #   'claim-1' => 'claim 1 value',
        #   'claim-2' => 'claim 2 value'
        # }
        def relevant_annotations(annotations)
          annotations = annotations.reject { |k, _| k.match(%r{^authn-jwt/#{@authenticator.service_id}$})}
          service_annotations = filtered_annotation_as_hash(
            annotations: annotations,
            regex: %r{^authn-jwt/#{@authenticator.service_id}/([^/]+)$}
          )

          if service_annotations.empty? # generic.empty? ||
            raise Errors::Authentication::Constraints::RoleMissingAnyRestrictions
          end

          filtered_annotation_as_hash(
            annotations: annotations,
            regex: %r{^authn-jwt/([^/]+)$}
          ).merge(service_annotations)
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
          # Validate that defined enforced claims are present
          verify_enforced_claims(authenticator_annotations) if @authenticator.enforced_claims.any?

          # Verify all claims are the same
          authenticator_annotations.each do |claim, value|
            validate_claim!(claim: claim, value: value, jwt: jwt)
          end

          # I suspect this error message isn't suppose to be written in the past tense....
          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictions.new)
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidateRestrictionsPassed.new)
        end

        def validate_identity(identity)
          unless identity.present?
            raise(Errors::Authentication::AuthnJwt::NoSuchFieldInToken, @authenticator.token_app_property)
          end

          return identity if identity.is_a?(String)

          raise Errors::Authentication::AuthnJwt::TokenAppPropertyValueIsNotString.new(
            @authenticator.token_app_property,
            identity.class
          )
        end

        # def identity_from_token_app_property(jwt:) #, token_app_property:, identity_path:)
        def retrieve_identity_from_jwt(jwt:)
          # Handle nested claim lookups
          identity = validate_identity(
            jwt.dig(*@authenticator.token_app_property.split('/'))
          )

          # If identity path is present, prefix it to the identity
          # Make sure we allow flexibility for optionally included trailing slash on identity_path
          (@authenticator.identity_path.to_s.split('/').compact << identity).join('/')
        end

        def identifier(id:, jwt:)
          # User ID should only be present without `token-app-property` because
          # we'll use the id to lookup the host/user
          # if id.present? && @authenticator.token_app_property.present?
          #   raise Errors::Authentication::AuthnJwt::IdentityMisconfigured
          # end

          # NOTE: `token_app_property` maps the specified jwt claim to a host of the
          # same name.
          if @authenticator.token_app_property.present? && !id.present?
            retrieve_identity_from_jwt(jwt: jwt) # , token_app_property: @authenticator.token_app_property, identity_path: @authenticator.identity_path)
          elsif id.present? && !@authenticator.token_app_property.present?
            id
          else
            raise Errors::Authentication::AuthnJwt::IdentityMisconfigured
          end
        end

        def validate_claim!(claim:, value:, jwt:)
          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionOnRequest.new(claim))

          claim_valid = ClaimContract.new(authenticator: @authenticator, utils: ::Util::ContractUtils).call(
            claim: claim,
            jwt: jwt,
            claim_value: value
          )

          unless claim_valid.success?
            raise(claim_valid.errors.first.meta[:exception])
          end

          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsValues.new(claim))
        end
      end
    end
  end
end
