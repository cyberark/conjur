# frozen_string_literal: true

require 'command_class'

module Conjur

  # This class handles the application of a Conjur Policy
  # `modification` input must be one of the following:
  #   - :create
  #   - :modify
  #   - :replace
  class ApplyPolicy
    extend CommandClass::Include

    class InvalidModification < StandardError; end

    command_class(
      dependencies: {
        current_user: nil,
        logger: nil,
        audit_logger: ::Audit.logger,
        loader: Loader::Orchestrate,
        policy_version: PolicyVersion,
        credential: Credentials
      },
      inputs: %i[modification policy request_obj]
    ) do
      def call
        validate_inputs(modification: @modification)

        policy_version_object = save_policy_version(
          policy: @policy,
          request: @request_obj,
          modification: @modification
        )
        policy_loader = @loader.new(policy_version_object)
        user_host_id_and_keys = @logger.measure(:debug, "Policy applied with '#{@modification}'") do
          apply_policy(
            modification: @modification,
            policy_loader: policy_loader
          )
        end

        @logger.measure(:debug, "Audit events written") do
          write_to_audit(policy_version_object: policy_version_object)
        end

        {
          created_roles: user_host_id_and_keys,
          version: policy_version_object.version
        }
      end

      private

      def validate_inputs(modification:)
        valid_modifiers = %i[create modify replace]
        return if valid_modifiers.include?(modification)

        raise InvalidModification, "Modification '#{modification.inspect}' is not valid. " \
          "The following are valid modificaction options: '#{valid_modifiers.inspect}'"
      end

      def apply_policy(policy_loader:, modification:)
        case modification
        when :create
          policy_loader.setup_db_for_new_policy
          policy_loader.delete_shadowed_and_duplicate_rows
          policy_loader.store_policy_in_db
        when :modify
          policy_loader.setup_db_for_new_policy
          policy_loader.delete_shadowed_and_duplicate_rows
          policy_loader.update_changed
          policy_loader.store_policy_in_db
        when :replace
          policy_loader.setup_db_for_new_policy
          policy_loader.delete_removed
          policy_loader.delete_shadowed_and_duplicate_rows
          policy_loader.update_changed
          policy_loader.store_policy_in_db
        end

        generate_new_host_and_user_api_keys(
          roles: policy_loader.new_roles.select { |role| %w[user host].member?(role.kind) }
        )
      end

      def write_to_audit(policy_version_object:)
        policy_version_object.policy_log.lazy.map(&:to_audit_event).each do |event|
          @audit_logger.log(event)
        end
      end

      def generate_new_host_and_user_api_keys(roles:)
        roles.each_with_object({}) do |role, memo|
          credentials = @credential[role: role] || @credential.create(role: role)
          role_id = role.id
          memo[role_id] = { id: role_id, api_key: credentials.api_key }
        end
      end

      def save_policy_version(policy:, request:, modification:)
        policy_version = @policy_version.new(
          role: @current_user,
          policy: policy,
          policy_text: request.raw_post,
          client_ip: request.ip
        )

        # Delete is permitted on modify and replace, but not on create
        policy_version.delete_permitted = %i[modify replace].include?(modification)
        policy_version.save
        policy_version
      end
    end
  end
end
