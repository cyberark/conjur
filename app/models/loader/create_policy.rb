# frozen_string_literal: true

# Responsible for creating policy. Called when a POST request is received
module Loader
  class CreatePolicy
    def initialize(loader)
      @loader = loader
    end

    def self.from_policy(policy_version)
      CreatePolicy.new(Loader::Orchestrate.new(policy_version))
    end

    def set_pubsub(sqs_pubsub)
      @loader.set_pubsub(sqs_pubsub)
    end

    def call
      Rails.logger.info("+++++++++++ call 1")
      @loader.setup_db_for_new_policy
      Rails.logger.info("+++++++++++ call 2")
      @loader.delete_shadowed_and_duplicate_rows
      Rails.logger.info("+++++++++++ call 3")
      @loader.store_policy_in_db
      Rails.logger.info("+++++++++++ call 4")
      @loader.release_db_connection
      Rails.logger.info("+++++++++++ call 5")
    end

    def new_roles
      @loader.new_roles
    end
  end
end
