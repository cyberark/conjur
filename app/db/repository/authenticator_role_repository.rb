# frozen_string_literal: true

module DB
  module Repository
    # This class is responsible for loading the variables associated with a
    # particular type of authenticator. Each authenticator requires a Data
    # Object and Data Object Contract (for validation). Data Objects that
    # fail validation are not returned.
    #
    # This class includes one public methods:
    #   - `find` - returns a single authenticator based on the provided type,
    #     account, and service identifier.
    #
    class AuthenticatorRoleRepository
      def initialize(authenticator:, role_contract: nil, role: Role, logger: Rails.logger)
        @authenticator = authenticator
        @role = role
        @logger = logger
        @role_contract = role_contract

        @success = ::SuccessResponse
        @failure = ::FailureResponse
      end

      def find(role_identifier:)
        role = @role[role_identifier.identifier]
        unless role.present?
          return @failure.new(
            "Failed to find role for: '#{role_identifier.identifier}'",
            exception: Errors::Authentication::Security::RoleNotFound.new(role_identifier.role_for_error),
            status: :bad_request
          )
        end

        return @success.new(role) unless role.resource?

        relevant_annotations(
          annotations: {}.tap { |h| role.resource.annotations.each {|a| h[a.name] = a.value }}
        ).bind do |relevant_annotations|
          validate_role_annotations_against_contract(
            annotations: relevant_annotations
          ).bind do
            annotations_match?(
              role_annotations: relevant_annotations,
              target_annotations: role_identifier.annotations
            ).bind do
              @success.new(role)
            end
          end
        end
      end

      private

      def validate_role_annotations_against_contract(annotations:)
        # If authenticator requires annotations, verify some are present
        if @authenticator.annotations_required && annotations.empty?
          return @failure.new(
            'This authenticator requires a role to include authenticator annotations',
            exception: Errors::Authentication::Constraints::RoleMissingAnyRestrictions,
            status: :unauthorized
          )
        end

        # Only run contract validations if they are present
        # This isn't functional, but how best to return something of use...?
        return @success.new(annotations) if @role_contract.nil?

        annotations.each do |annotation, value|
          annotation_valid = @role_contract.new(authenticator: @authenticator, utils: ::Util::ContractUtils).call(
            annotation: annotation,
            annotation_value: value,
            annotations: annotations
          )
          next if annotation_valid.success?

          return @failure.new(
            annotation_valid.errors.first,
            exception: annotation_valid.errors.first.meta[:exception],
            status: :unauthorized
          )
        end
        @success.new(annotations)
      end


      # Need to account for the following two options:
      # Annotations relevant to specific authenticator
      # - !host
      #   id: myapp
      #   annotations:
      #     authn-jwt/raw/ref: valid

      # Annotations relevant to type of authenticator
      # - !host
      #   id: myapp
      #   annotations:
      #     authn-jwt/project_id: myproject
      #     authn-jwt/aud: myaud

      def relevant_annotations(annotations:)
        # Verify that at least one service specific auth token is present
        if annotations.keys.any? { |k, _| k.include?(@authenticator.type.to_s) } &&
            !annotations.keys.any? { |k, _| k.include?("#{@authenticator.type}/#{@authenticator.service_id}") }
            return @failure.new(
              'Role mush include some restrications',
              exception: Errors::Authentication::Constraints::RoleMissingAnyRestrictions,
              status: :unauthorized
            )
        end

        generic = annotations
          .select{|k, _| k.count('/') == 1 }
          .select{|k, _| k.match?(%r{^authn-jwt/})}
          .reject{|k, _| k.match?(%r{^authn-jwt/#{@authenticator.service_id}})}
          .transform_keys{|k| k.split('/').last}

        specific = annotations
          .select{|k, _| k.count('/') > 1 }
          .select{|k, _| k.match?(%r{^authn-jwt/#{@authenticator.service_id}/})}
          .transform_keys{|k| k.split('/').last}

        @success.new(generic.merge(specific))
      end

      def annotations_match?(role_annotations:, target_annotations:)
        # If there are no annotations to match, just return
        return @success.new(role_annotations) if target_annotations.empty?

        role_annotations.each do |annotation, value|
          next unless annotation.present?

          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionOnRequest.new(annotation))
          if target_annotations.key?(annotation) && target_annotations[annotation] == value
            @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsValues.new(annotation))
            next
          end

          unless target_annotations.key?(annotation)
            return @failure.new(
              "Role annotation: '#{annotation}' is not present in the authorization payload",
              exception: Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing.new(annotation),
              status: :unauthorized
            )
          end

          return @failure.new(
            "Role annotation: '#{annotation}' is invalid",
            Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions.new(annotation),
            status: :unauthorized
          )
        end

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictions.new)
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidateRestrictionsPassed.new)

        @success.new(role_annotations)
      end
    end
  end
end
