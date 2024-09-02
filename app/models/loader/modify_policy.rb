# frozen_string_literal: true

# Responsible for modifying policy. Called when a PATCH request is received
module Loader
  class ModifyPolicy
    def initialize(loader)
      @loader = loader
    end

    def self.from_policy(policy_version)
      ModifyPolicy.new(Loader::Orchestrate.new(policy_version))
    end

    def call
      @loader.setup_db_for_new_policy
      
      @loader.delete_shadowed_and_duplicate_rows

      @loader.upsert_policy_records

      @loader.clean_db

      @loader.store_auxiliary_data

      @loader.release_db_connection
    end

    def new_roles
      @loader.new_roles
    end

    def self.authorize(current_user, resource)
      # No-op
    end
  end
end
