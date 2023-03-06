# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2
      class ResolveIdentity
        def initialize(authenticator:, logger: Rails.logger)
          @authenticator = authenticator
          @logger = logger
        end

        def call(identifier:, account:, allowed_roles:)
          # NOTE: `token_app_property` maps the specified jwt claim to a host of the
          # same name.
          if @authenticator.token_app_property.present?
            # binding.pry

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

            # binding.pry
            allowed_roles.each do |role|
              role_account, _, role_id = role.id.split(':')
              next unless role_account == account && identity == role_id

              # Gather Authenticator specific annotations
              authenticator_annotations = role.resource.annotations.select { |a| a.name.match(/^authn-jwt\//) }

              # At least one relevant annotation is required
              if authenticator_annotations.empty?
                raise Errors::Authentication::Constraints::RoleMissingAnyRestrictions
              end

              service_id_annotations = authenticator_annotations
                .select { |a| a.name.match(/^authn-jwt\/#{@authenticator.service_id}\//) }

              if service_id_annotations.empty?
                raise Errors::Authentication::Constraints::RoleMissingAnyRestrictions
              end

              # Ensure service specific annotations match
              service_id_annotations.each do |service_id_annotation|
                claim = service_id_annotation.name.gsub(/^authn-jwt\/#{@authenticator.service_id}\//, '')
                @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionOnRequest.new(claim))

                if service_id_annotation.value.empty?
                  raise Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven, claim
                end

                # Ensure claim contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/")
                unless claim.count('a-zA-Z0-9\/\-_') == claim.length
                  raise Errors::Authentication::AuthnJwt::InvalidRestrictionName, claim
                end

                identity_value = identifier.dig(*claim.split('/'))
                if identity_value.blank?
                  raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing, claim
                end

                unless identity_value == service_id_annotation.value
                  raise Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions, claim
                end

                @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsValues.new(claim))
              end

              # Ensure general restrictions match
              (authenticator_annotations - service_id_annotations).each do |authenticator_annotation|
                # ignore invalid service ID annotations (ex. authn-jwt/<service-id>:)
                next if authenticator_annotation.name == "authn-jwt/#{@authenticator.service_id}"

                # ignore annotations for differen service IDs
                next if authenticator_annotation.name.split('/').length > 2

                claim = authenticator_annotation.name.gsub(/^authn-jwt\//, '')
                @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatingResourceRestrictionOnRequest.new(claim))

                if authenticator_annotation.value.empty?
                  raise Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven, claim
                end

                # Ensure claim contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/")
                unless claim.count('a-zA-Z0-9\/\-_') == claim.length
                  raise Errors::Authentication::AuthnJwt::InvalidRestrictionName, claim
                end

                identity_value = identifier.dig(*claim.split('/'))
                if identity_value.blank?
                  raise Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing, claim
                end

                unless identity_value == authenticator_annotation.value
                  raise Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions, claim
                end

                @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictionsValues.new(claim))
              end
              # I suspect this error message isn't suppose to be written int the past tense....
              @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictions.new)
              @logger.debug(LogMessages::Authentication::AuthnJwt::ValidateRestrictionsPassed.new)
              return role
            end

            # binding.pry
            # If not found, raise error with the assumed intended target:
            raise(Errors::Authentication::Security::RoleNotFound, "host/#{identity}")
          end

          binding.pry
          raise(Errors::Authentication::Security::RoleNotFound, identifier)
        end
      end
    end
  end
end
