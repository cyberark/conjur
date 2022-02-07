# frozen_string_literal: true

require 'json'
require 'logs'
require 'app/models/loader/orchestrate'
require 'app/domain/logs'

# BootstrapLoader is used to load an initial "root" policy when the database is completely empty.
class RootLoader
  class << self
    # Load a policy into the specified account.
    # 
    # The policy will be owned by the 'user:admin' role. If the environment variable CONJUR_ADMIN_PASSWORD
    # exists, it will be used as the admin password (potentially resetting the existing password).
    #
    # The policy id is "root". The role and resource records for the policy will be created automatically
    # if they don't already exist. 
    def load account, filename
      start_t = Time.now
      Sequel::Model.db.transaction do
        admin_id = "#{account}:user:admin"
        admin = ::Role[admin_id] || ::Role.create(role_id: admin_id)
        if admin_password = ENV['CONJUR_ADMIN_PASSWORD']
          $stderr.puts("Setting 'admin' password")
          set_admin_password(admin, admin_password)
        end

        root_policy_resource = Loader::Types.find_or_create_root_policy(account)
        policy = save_submitted_policy(
          role: admin, 
          policy: root_policy_resource, 
          filename: filename
        )

        acc_roles = accepted_roles(policy)
        created_roles = create_roles(acc_roles)

        $stderr.puts(
          JSON.pretty_generate(
            created_roles: created_roles,
            version: policy[:version]
          )
        )

        end_t = Time.now
        $stderr.puts("Loaded policy in #{end_t - start_t} seconds")
      end
    end

    def set_admin_password(admin_role, password)
      admin_credentials = Credentials[role: admin_role] || Credentials.create(role: admin_role)
      admin_credentials.password = password
      admin_credentials.save
    end

    def create_roles(accepted_roles)
      accepted_roles.each_with_object({}) do |role, memo|
        credentials = Credentials[role: role] || Credentials.create(role: role)
        role_id = role.id
        memo[role_id] = { id: role_id, api_key: credentials.api_key }
      end
    end

    def accepted_roles(policy_version)
      policy_action = Loader::ReplacePolicy.from_policy(policy_version)
      policy_action.call
      policy_action.new_roles.select do |role|
        %w[user host].member?(role.kind)
      end
    end

    def save_submitted_policy(role:, policy:, filename:)
      policy_version = PolicyVersion.new(role: role, policy: policy, policy_text: File.read(filename))
      policy_version.policy_filename = filename
      policy_version.delete_permitted = true
      policy_version.save
    end
  end
end
