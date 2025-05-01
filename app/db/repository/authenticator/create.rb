# frozen_string_literal: true

module DB
  module Repository
    module Authenticator
      class CreateAuthenticator

        def call(authenticator:)
          branch = authenticator.branch
          branch_policy_id = full_resource_id(authenticator.account, "policy", branch)
          owner_id = authenticator.owner
          name = authenticator.authenticator_name
          enabled = authenticator.enabled
          annotations = authenticator.annotations
          account = authenticator.account

          # Add the authenticator policy to role
          resource_id = full_resource_id(authenticator.account, "policy", "#{branch}/#{name}")
          Role.find_or_create(role_id: resource_id)
          
          # Create the authenticator policy :
          # Authenticator policy id - conjur:policy:conjur/authn-#{type}/#{name}
          # Authenticator policy policy_id - conjur:policy:conjur/authn-#{type}
          # Authenticator policy owner_id - is the input owner_id or conjur:policy:conjur/authn-#{type}
          authenticator_policy_id = create_resource(
            "policy",
            branch_policy_id,
            owner_id,
            branch,
            name,
            account
          )[:resource_id]

          # Create the authenticator webservice :
          # Authenticator webservice id - conjur:webservice:conjur/authn-#{type}/#{name}
          # Authenticator webservice policy_id - branch_policy_id -> conjur:policy:conjur/authn-#{type}
          # Authenticator webservice owner_id - authenticator_policy_id -> conjur:policy:conjur/authn-#{type}/#{name}
          create_resource(
            "webservice",
            branch_policy_id,
            authenticator_policy_id,
            branch,
            name,
            account
          )

          # Create the authenticator status :
          # Authenticator status webservice id - conjur:webservice:conjur/authn-#{type}/#{name}/status
          # Authenticator webservice policy_id - branch_policy_id -> conjur:policy:conjur/authn-#{type}
          # Authenticator webservice owner_id - authenticator_policy_id -> conjur:policy:conjur/authn-#{type}/#{name}
          create_resource(
            "webservice",
            branch_policy_id,
            authenticator_policy_id,
            branch,
            "#{name}/status",
            account
          )

          # Create the operators group :
          # Operators group id - conjur:group:conjur/authn-#{type}/#{name}/operators
          # Operators group policy_id - branch_policy_id -> conjur:policy:conjur/authn-#{type}
          # Operators group owner_id - authenticator_policy_id -> conjur:policy:conjur/authn-#{type}/#{name}
          create_resource(
            "group",
            branch_policy_id,
            authenticator_policy_id,
            branch,
            "#{name}/operators",
            account
          )

          # Add the operators group to role table
          operators_group_id = full_resource_id(authenticator.account, "group", "#{branch}/#{name}/operators")
          Role.find_or_create(role_id: operators_group_id)

          # Create the apps group :
          # Apps group id - conjur:group:conjur/authn-#{type}/#{name}/apps
          # Apps group policy_id - branch_policy_id -> conjur:policy:conjur/authn-#{type}
          # Apps group owner_id - authenticator_policy_id -> conjur:policy:conjur/authn-#{type}/#{name}
          create_resource(
            "group",
            branch_policy_id,
            authenticator_policy_id,
            branch,
            "#{name}/apps",
            account
          )

          # Add the apps group to role table
          apps_group_id = full_resource_id(authenticator.account, "group", "#{branch}/#{name}/apps")
          Role.find_or_create(role_id: apps_group_id)

          # Create the permissions for the authenticator webservice and status
          status_webservice_id = full_resource_id(authenticator.account, "webservice", "#{branch}/#{name}/status")
          auth_webservice_id = full_resource_id(authenticator.account, "webservice", "#{branch}/#{name}")

          create_permission(status_webservice_id, "read", operators_group_id, branch_policy_id)
          create_permission(auth_webservice_id, "read", operators_group_id, branch_policy_id)
          create_permission(auth_webservice_id, "read", apps_group_id, branch_policy_id)
          create_permission(auth_webservice_id, "authenticate", apps_group_id, branch_policy_id)

          set_auth_enabled(auth_webservice_id, enabled)

          annotations.each do |name, value|
            Annotation.create(
              resource_id: auth_webservice_id,
              policy_id: authenticator_policy_id,
              name: name,
              value: value
            )
          end unless annotations.nil?

          # **Iterate over `variables` in `authenticator_dict` and create corresponding resources**
          authenticator.variable_map&.each do |key, value|
            if key.to_s == "identity"
              value.each do |identity_key, identity_value|
                insert_variable(
                  identity_key,
                  identity_value,
                  branch_policy_id,
                  authenticator_policy_id,
                  branch,
                  name,
                  account
                )
              end
            else
              insert_variable(
                key,
                value,
                branch_policy_id,
                authenticator_policy_id,
                branch,
                name,
                account
              )
            end
          end

          authenticator
        end

        private

        def insert_variable(key, value, branch_policy_id, authenticator_policy_id, branch, name, account)
          # Convert key name to dasherized format (e.g., `claim_aliases` → `claim-aliases`)
          variable_name = key.to_s.dasherize

          # Create variable resource under the `identity` namespace within the authenticator's branch
          resource_id = create_resource(
            "variable",
            branch_policy_id,
            authenticator_policy_id,
            branch,
            "#{name}/#{variable_name}",
            account
          )[:resource_id]

          # Convert value to string if it is not already a string
          value = value.to_s unless value.is_a?(String)

          # Store the identity variable value in the Secret storage if provided
          Secret.create(resource_id: resource_id, value: value) unless value.nil?
        end

        def set_auth_enabled(auth_webservice_id, enabled)
          auth_config = AuthenticatorConfig.find_or_create(resource_id: auth_webservice_id) do |config|
            config.enabled = enabled
          end

          if auth_config.nil?
            @logger.error("Authenticator config creation failed for : #{auth_webservice_id}")
            return nil
          end

          auth_config
        end

        def create_resource(kind, policy_id, owner_id, branch, name, account)
          resource_id = full_resource_id(account, kind, "#{branch}/#{name}")
          args = { resource_id: resource_id }
          args[:owner_id] = owner_id
          args[:policy_id] = policy_id

          resource = Resource.create(**args)
          if resource.nil?
            @logger.error(
              "Resource creation failed for resource_id:" \
              " #{resource_id} owner_id: #{owner_id} policy_id: #{policy_id}"
            )
            return nil
          end

          resource
        end

        def create_permission(resource_id, privilege, role_id, policy_id)
          args = {
            resource_id: resource_id,
            privilege: privilege,
            role_id: role_id,
            policy_id: policy_id
          }
          perm = Permission.create(**args) 

          if perm.nil?
            @logger.error(
              "Permission creation failed for resource_id: " \
              "#{resource_id} privilege: #{privilege} role_id: #{role_id} policy_id: {policy_id}"
            )
            return
          end

          perm
        end


        def full_resource_id(account, type, name)
          if name.start_with?("/")
            name = name[1..-1]
          end

          "#{account}:#{type}:#{name}"
        end
      end
    end
  end
end
