# frozen_string_literal: true

module Loader
  module Handlers
    # extends the policy loader to store role credentials (passwords). This occurs
    # after the initial policy load, since variable values are not part of the policy load
    module Password
  
      # When a public key is encountered in a policy, it is saved here. It can't be written directly into
      # the temporary schema, because that schema doesn't have a secrets table. The merge algorithm only operates
      # on the RBAC tables.
      def handle_password id, password
        policy_passwords << [ id, password ]
      end
  
      # Store all passwords which were encountered during the policy load. The passwords aren't declared in the
      # policy itself, they are obtained from the environment. This generally only happens when setting up the
      # +admin+ user in the bootstrap phase, but setting passwords for other users can be useful for dev/test.
      def store_passwords
        policy_passwords.each do |entry|
          id, password = entry
          warn "Setting password for '#{id}'"
          role = ::Role[id]
          role.password = password
          role.save
        end
      end
  
      def policy_passwords
        @policy_passwords ||= []
      end
    end
  end
end
