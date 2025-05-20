# frozen_string_literal: true

module DB
  module Repository
    module Authenticator
      class CreateAuthenticator
        def initialize(authenticator:)
          @authenticator = authenticator
          @owner_id = authenticator.owner
          @service_id = authenticator.authenticator_name
          @annotations = authenticator.annotations
          @account = authenticator.account
          @enabled = authenticator.enabled
          @branch = authenticator.branch
          @variables = authenticator.variable_map

          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        def call
          add_authenticator_role
          build_policy_tree
          endable_authenticator
          add_annotations
          add_varibales(@variables)

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
          Role.find_or_create(role_id: "#{policy_branch}/#{@service_id}")
        end

        def endable_authenticator
          AuthenticatorConfig.find_or_create(resource_id: webservice, enabled: @enabled)
        end

        def policy_branch
          "#{@account}:policy:#{@branch}"
        end

        def owner_id
          policy_branch unless @owner_id
          
          @owner_id
        end

        def group
          "#{@account}:group:#{@branch}/#{@service_id}"
        end

        def webservice
          "#{@account}:webservice:#{@branch}/#{@service_id}"
        end

        def add_permission(resource, permissions_map)
          permissions_map.each do |group, permissions| 
            role = Role.find_or_create(role_id: group.to_s)
            permissions.each{ |permission| resource.permit(permission, role, policy_id: policy_branch) }
          end 
        end

        def add_varibales(variables)
          variables&.each do |key, value|
            if key.to_s == "identity"
              set_varibales(value)
            else
              Resource.create(
                resource_id: "#{webservice}/#{key}",
                owner_id: owner_id,
                policy_id: policy_branch
              )
              unless value.nil?
                ::Secret.create(
                  resource_id: "#{webservice}/#{key}",
                  value: value.to_s
                ) 
              end
            end
          end
        end

        def add_annotations
          @annotations&.each do |name, value|
            Annotation.create(
              resource_id: webservice,
              policy_id: "#{policy_branch}/#{@service_id}",
              name: name,
              value: value
            )
          end
        end

        # Creates the policies for the autheenticators using a table to make it clear whats being created
        def build_policy_tree
          [
            {
              id: "#{policy_branch}/#{@service_id}",
              owner: owner_id,
              permissions: nil
            },
            {
              id: "#{group}/operators",
              owner: "#{policy_branch}/#{@service_id}",
              permissions: nil
            },
            {
              id: "#{group}/apps",
              owner: "#{policy_branch}/#{@service_id}",
              permissions: nil
            },
            {
              id: webservice,
              owner: "#{policy_branch}/#{@service_id}",
              permissions: {
                "#{group}/operators": %w[read authenticate],
                "#{group}/apps": ["read"]
              } 
            },
            {
              id: "#{webservice}/status",
              owner: "#{policy_branch}/#{@service_id}",
              permissions: { "#{group}/apps": ["read"] } 
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
