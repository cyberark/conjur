# frozen_string_literal: true

require 'command_class'

module Commands
  module Authentication
    IssueToken ||= CommandClass.new(
      dependencies: {
        json_lib: JSON,
        slosilo_lib: Slosilo
      },
      inputs: %i[message]
    ) do
      def call
        claims = @json_lib.parse(@message)
        claims = claims.slice("account", "sub", "exp", "cidr")
        (account = claims.delete("account")) || raise("'account' is required")
        raise "'sub' is required" unless claims['sub']

        key = @slosilo_lib["authn:#{account}"]
        if key
          key.issue_jwt(claims).to_json
        else
          raise "No signing key found for account #{account.inspect}"
        end
      end
    end
  end
end
