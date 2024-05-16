# frozen_string_literal: true

# Parses a policy -- from a YAML file -- into records using Conjur::PolicyParser.
# Versioning, storage in DB, and results presentation are left for the caller.

module Commands
  module Policy
    class Parse

      def call(account:, policy_id:, owner_id:, policy_text:, policy_filename:, root_policy:)

        resolved_records = []
        error = nil

        begin
          yaml_records = Conjur::PolicyParser::YAML::Loader.load(policy_text, policy_filename)

          unless root_policy
            # Wraps the input records in a policy whose id is the
            # +policy+ id, and whose owner is the +policy_admin+.
            policy_record = Conjur::PolicyParser::Types::Policy.new(policy_id)
            policy_record.owner = Conjur::PolicyParser::Types::Role.new(owner_id)
            policy_record.account = account
            policy_record.body = yaml_records

            yaml_records = policy_record
          end

          resolved_records = Conjur::PolicyParser::Resolver.resolve(yaml_records, account, owner_id)

        rescue Conjur::PolicyParser::Invalid => err
          # Parse-specific errors arrive in the full error format:
          error = err.message

          # The full error format is composed of these fields:
          #   "Error at line #{mark.line}, column #{mark.column} in #{filename} : #{message}"
          # The 'message' field is readable as 'detail_message'.
          message = err.detail_message

          # The parse-specific error is what we want to enhance with explainer information.
          explainer = Commands::Policy::ExplainError.new
          explanation = ""
          error += "\n#{explanation}" unless explanation == nil

          $stderr.puts(error)

        rescue => err
          # Other runtime errors are captured but not enhanced.
          error = err.message

          $stderr.puts(error)

        end

        PolicyParse.new(resolved_records, error)
      end
    end
  end
end
