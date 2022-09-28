module Authentication
  module AuthnJwt
    module V2
      class ResolveIdentity
        def initialize(logger: Rails.logger)
          @logger = logger
        end

        def call(identity:, account:, allowed_roles:, authenticator:)
          # make sure role has a resource (ex. user, host)
          roles = allowed_roles.select(&:resource?)
          roles = roles.select{|i| i.kind == 'host'}
          identifier = identity[authenticator.identifying_claim]
          matching_roles = roles.select do |role|
            role_account, _, role_id = role.id.split(':')

            role_id = role_id.split('/').last

            next unless role_account == account
            next unless identifier == role_id

            annotations = {}.tap do |matching_annotation|
              role.resource.annotations.each do |annotation|

                claim = annotation.name.scan(/^authn-jwt\/#{authenticator.service_id}\/(\w+)/).flatten.first
                next if claim.empty?

                matching_annotation[claim] = annotation.value
              end
            end

            annotations.each do |claim, value|
              next unless identity[claim] == value
            end

            role
          end

          if matching_roles.empty?
            raise(Errors::Authentication::Security::RoleNotFound, identifier)
          end

          if matching_roles.count > 1
            raise(Errors::Authentication::Security::MultipleMatches, identifier)
          end

          matching_roles.first
        end
      end
    end
  end
end
