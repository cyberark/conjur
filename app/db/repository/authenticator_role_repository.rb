module DB
  module Repository
    # This class is responsible for loading the variables associated with a
    # particular type of authenticator. Each authenticator requires a Data
    # Object and Data Object Contract (for validation). Data Objects that
    # fail validation are not returned.
    #
    # This class includes two public methods:
    #   - `find_all` - returns all available authenticators of a specified type
    #     from an account
    #   - `find` - returns a single authenticator based on the provided type,
    #     account, and service identifier.
    #
    class AuthenticatorRoleRepository
      def initialize(authenticator:, role_contract:, role: Role, logger: Rails.logger)
        @authenticator = authenticator
        @role_contract = role_contract
        @role = role
        @logger = logger
      end

      def find(role_identifier:)
        role = @role[role_identifier.role_identifier]
        unless role.present?
          raise(Errors::Authentication::Security::RoleNotFound, role_identifier.role_for_error)
        end

        role_annotations = relevant_annotations(
          annotations: {}.tap { |h| role.resource.annotations.each {|a| h[a.name] = a.value }},
        )
        annotations_match?(
          role_annotations: role_annotations,
          target_annotations: role_identifier.annotations
        )

        role
      end

      private

      def validate_role_annotations(annotations:)
        if @authenticator.annotations_required && annotations.empty?
          raise(Errors::Authentication::Constraints::RoleMissingAnyRestrictions)
        end

        annotations.each do |annotation, value|
          annotation_valid = @role_contract.new(authenticator: @authenticator, utils: ::Util::ContractUtils).call(
            annotation: annotation,
            annotation_value: value,
            annotations: annotations
          )
          next if annotation_valid.success?

          raise(annotation_valid.errors.first.meta[:exception])
        end
      end

      # Need to account for the following two options:
      # - !host
      #   id: myapp
      #   annotations:
      #     authn-jwt/raw/ref: valid

      # - !host
      #   id: myapp
      #   annotations:
      #     authn-jwt/project_id: myproject
      #     authn-jwt/aud: myaud

      def relevant_annotations(annotations:, authenticator:, relevant_annotations:)
        # Verify that at least one service specific auth token is present
        if annotations.keys.any?{|k,_|k.include?(authenticator.type.to_s) } &&
            !annotations.keys.any?{|k,_|k.include?("#{authenticator.type}/#{authenticator.service_id}") }
          raise(Errors::Authentication::Constraints::RoleMissingAnyRestrictions)
        end

        generic = annotations
          .select{|k, _| k.count('/') == 1 }
          .select{|k, _| k.match?(%r{^authn-jwt/})}
          .reject{|k, _| k.match?(%r{^authn-jwt/#{authenticator.service_id}})}
          .transform_keys{|k| k.split('/').last}

        specific = annotations
          .select{|k, _| k.count('/') > 1 }
          .select{|k, _| k.match?(%r{^authn-jwt/#{authenticator.service_id}/})}
          .transform_keys{|k| k.split('/').last}

        relevant_annotations = generic.merge(specific)

        validate_role_annotations(annotations: relevant_annotations, authenticator: authenticator, relevant_annotations: relevant_annotations)
        relevant_annotations
      end

      def annotations_match?(role_annotations:, target_annotations:)
        # If there are no annotations to match, just return
        return if target_annotations.empty?

        role_annotations.each do |annotation, value|
          next unless annotation.present?

          @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionOnRequest.new(annotation))
          if target_annotations.key?(annotation) && target_annotations[annotation] == value
            @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsValues.new(annotation))
            next
          end

          unless target_annotations.key?(annotation)
            raise(Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing, annotation)
          end

          raise(Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions, annotation)
        end

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictions.new)
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidateRestrictionsPassed.new)
      end
    end
  end
end
