# frozen_string_literal: true
  
# Responsible for replacing policy. Called when a PUT request is received
module Loader
  class ReplacePolicy
    def initialize(loader)
      @loader = loader
    end

    def self.from_policy(policy_version)
      ReplacePolicy.new(Loader::Orchestrate.new(policy_version))
    end

    def call
      @loader.setup_db_for_new_policy

      @loader.delete_removed
      
      @loader.delete_shadowed_and_duplicate_rows

      @loader.update_changed

      @loader.store_policy_in_db
    end

    def new_roles
      @loader.new_roles
    end
  end
end
