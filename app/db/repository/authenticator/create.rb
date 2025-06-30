# frozen_string_literal: true

module DB
  module Repository
    module Authenticator
      class CreateAuthenticator
        def initialize(authenticator:)
          @authenticator = authenticator
          @service_id = authenticator.authenticator_name

          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        def call
          unless Resource[policy_branch]
            return @failure.new(
              "Policy '#{@authenticator.branch}' is required to create a new authenticator.",
              status: :not_found
            ) 
          end

          add_authenticator_role
          create_webservice_branch
          build_policy_tree
          enable_authenticator
          add_annotations
          add_variables(@authenticator.variables)

          @success.new(@authenticator)
        rescue Sequel::UniqueConstraintViolation, Sequel::ConstraintViolation => e
          @failure.new(
            "The authenticator already exists.",
            status: :conflict,
            exception: e
          )  
        end

        private

        def add_authenticator_role
          Role.find_or_create(role_id: webservice_branch)
        end

        def enable_authenticator
          AuthenticatorConfig.find_or_create(resource_id: webservice, enabled: @authenticator.enabled)
        end

        def webservice_branch
          "#{@authenticator.account}:policy:#{@authenticator.webservice_branch}"
        end

        def policy_branch
          "#{@authenticator.account}:policy:#{@authenticator.branch}"
        end

        def authn_variables
          "#{@authenticator.account}:variable:#{@authenticator.webservice_branch}"
        end

        def owner_id
          policy_branch unless @authenticator.owner
          
          @authenticator.owner
        end

        def group
          "#{@authenticator.account}:group:#{@authenticator.webservice_branch}"
        end

        def webservice
          "#{@authenticator.account}:webservice:#{@authenticator.webservice_branch}"
        end

        def add_permission(resource, permissions_map)
          permissions_map.each do |group, permissions| 
            role = Role.find_or_create(role_id: group.to_s)
            permissions.each{ |permission| resource.permit(permission, role, policy_id: policy_branch) }
          end 
        end

        def add_variables(variables)
          variables&.each do |key, value|
            if key.to_s == "identity"
              add_variables(value)
            else
              Resource.create(
                resource_id: "#{authn_variables}/#{key.to_s.dasherize}",
                owner_id: webservice_branch,
                policy_id: policy_branch
              )
              unless value.nil?
                ::Secret.create(
                  resource_id: "#{authn_variables}/#{key.to_s.dasherize}",
                  value: value.to_s
                ) 
              end
            end
          end
        end

        def add_annotations
          @authenticator.annotations&.each do |name, value|
            Annotation.create(
              resource_id: webservice,
              policy_id: webservice_branch,
              name: name,
              value: value
            )
          end
        end

        # Creates the webservice branch for other resources to be loaded into
        def create_webservice_branch
          # GCP gets loaded into the authenticator branch itself so the webservice branch already exists
          return if @authenticator.type == "authn-gcp"

          Resource.create(
            resource_id: webservice_branch,
            owner_id: owner_id,
            policy_id: policy_branch
          )
        end

        # Creates the policies for the autheenticators using a table to make it clear whats being created
        def build_policy_tree
          [
            {
              id: "#{group}/operators",
              owner: webservice_branch,
              permissions: nil
            },
            {
              id: "#{group}/apps",
              owner: webservice_branch,
              permissions: nil
            },
            {
              id: webservice,
              owner: webservice_branch,
              permissions: {
                "#{group}/operators": %w[read],
                "#{group}/apps": %w[read authenticate]
              } 
            },
            {
              id: "#{webservice}/status",
              owner: webservice_branch,
              permissions: { "#{group}/operators": ["read"] } 
            }
          ].each do |resource|
            new_resource = Resource.create(
              resource_id: resource[:id],
              owner_id: resource[:owner],
              policy_id: policy_branch
            )

            next unless resource[:permissions]

            add_permission(new_resource, resource[:permissions])
          end
        end
      end
    end
  end
end
