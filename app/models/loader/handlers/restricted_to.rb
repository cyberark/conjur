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
  
      def store_restricted_to(delete_permitted)
        credentials = []
        policy_restricted_to_records.each do |entry|
          id, cidr = entry

          # Normalize addresses to always include network mask e.g. 1.1.1.1 => 1.1.1.1/32, 2.2.0.0/16 => 2.2.0.0/16.
          # This normalization is necessary in order to apply proper array union when deletion is not permitted.
          cidr = Array(cidr).map { |addr| Conjur::CIDR.new(addr).to_s }

          # NOTE: By default restricted_to will be an empty array
          role = ::Role[id]
          original_restricted_to = role.restricted_to.map(&:to_s)

          role.restricted_to = Sequel.pg_array(
            delete_permitted ? cidr : (original_restricted_to | cidr),
            :cidr
          )

          role.save
          new_restricted_to = role.restricted_to.map(&:to_s)

          # TODO: not a fan of this but it works for now.
          # Only return the restricted_to if it was newly created or updated
          next unless original_restricted_to != new_restricted_to

          credentials << {
            role_id: id,
            restricted_to: new_restricted_to
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
