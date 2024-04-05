# frozen_string_literal: true

# Parses a policy -- from a YAML file -- into records using Conjur::PolicyParser.
# Versioning, storage in DB, and results presentation are left for the caller.

require 'exceptions/enhanced_policy'

module Commands
  module Policy
    class Parse

      def call(account:,
        policy_id:,
        owner_id:,
        policy_text:,
        policy_filename:,
        root_policy:
      )

        # in anticipation of no errors...
        resolved_records = []
        error = nil

        # policy_filename is deprecated -- Policy class does not require it but because
        #   the parser error classes use it we'll either pass the name or provide a substitute
        @policy_filename = policy_filename
        @policy_filename = "policy" if policy_filename.to_s.empty?

        begin
          yaml_records = Conjur::PolicyParser::YAML::Loader.load(policy_text, @policy_filename)

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

        rescue Conjur::PolicyParser::Invalid => e
          # Error format, per gems/policy-parser/lib/conjur/policy/invalid.rb
          #   "Error at line #{mark.line}, column #{mark.column} in #{filename} : #{message}"
          # The 'message' field is readable as 'detail_message'.
          error = Exceptions::EnhancedPolicyError.new(
            original_error: e,
            detail_message: e.detail_message
          )

        rescue Conjur::PolicyParser::ResolverError => e
          # Error format, per gems/policy-parser/lib/conjur/policy/invalid.rb
          # The 'message' field is the same as 'detail_message'.
          error = Exceptions::EnhancedPolicyError.new(
            original_error: e
          )

        rescue Psych::SyntaxError => e
          # Error format, per https://github.com/ruby/psych/blob/master/lib/psych/syntax_error.rb
          # https://github.com/ruby/psych/blob/master/lib/psych/syntax_error.rb
          #   err      = [problem, context].compact.join ' '
          #   filename = file || '<unknown>'
          #   message  = "(%s): %s at line %d column %d" % [filename, err, line, col]
          error = Exceptions::EnhancedPolicyError.new(
            original_error: e,
            detail_message: [e.problem, e.context].compact.join(' ')
          )

        rescue ArgumentError => e
          # From policy-parser
          # from app/models/loader/types
          # Will we see this here? => No.  This results from Orchestrate
          # => controller level
          error = Exceptions::EnhancedPolicyError.new(
            original_error: e
          )

        rescue NoMethodError => e
          # This is rescued by ApplicationController, so pass it up.
          error = Exceptions::EnhancedPolicyError.new(
            original_error: e
          )

        rescue => e
          # Everything else can be wrapped but may not be safe to raise.
          error = Exceptions::EnhancedPolicyError.new(
            original_error: e
          )
          error.original_error = nil
        end

        PolicyParse.new(resolved_records, error)
      end
    end
  end
end
