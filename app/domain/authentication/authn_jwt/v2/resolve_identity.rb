# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2
      class ResolveIdentity
        def initialize(authenticator:)
          @authenticator = authenticator
        end

        def call(identifier:, account:, allowed_roles:)
          # Note: `token_app_property` maps the specified jwt claim to a host of the
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
              return role if role_account == account && identity == role_id
            end
            # binding.pry
            # If not found, raise error with the assumed intended target:
            raise(Errors::Authentication::Security::RoleNotFound, "host/#{identity}")
          end

          # binding.pry
          raise(Errors::Authentication::Security::RoleNotFound, identifier)
        end
      end
    end
  end
end
