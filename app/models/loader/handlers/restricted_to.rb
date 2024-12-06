# frozen_string_literal: true

module Loader
  module Handlers
    # extends the policy loader to store the authentication network restriction
    # on a role's credentials.
    module RestrictedTo
  
      # When a cidr restriction is encountered in a policy, it is saved here. It can't be written directly 
      # into the temporary schema, because that schema doesn't have a credentials table. 
      def handle_restricted_to id, cidr
        policy_restricted_to_records << [ id, cidr ]
      end
  
      def store_restricted_to
        credentials = []
        policy_restricted_to_records.each do |entry|
          id, cidr = entry
          role = ::Role[id]
          original_restricted_to = role.restricted_to.map(&:to_s)

          # NOTE: By default restricted_to will be an empty array
          role.restricted_to = Sequel.pg_array(Array(cidr), :cidr) if cidr
          role.save
          new_restricted_to = role.restricted_to.map(&:to_s)

          next unless cidr

          # TODO: not a fan of this but it works for now.
          # Only return the restricted_to if it was newly created or updated
          next unless original_restricted_to != new_restricted_to

          credentials << {
            role_id: id,
            restricted_to: Array(cidr)
          }
        end
        credentials
      end
  
      def policy_restricted_to_records
        @policy_restricted_to_records ||= []
      end
    end
  end
end
