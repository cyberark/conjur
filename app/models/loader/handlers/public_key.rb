# frozen_string_literal: true

module Loader
  module Handlers
    # extends the policy loader to store public keys for users as variables. This happens
    # after the initial policy load, since variable values are not part of the policy load
    module PublicKey
  
      # When a public key is encountered in a policy, it is saved here. It can't be written directly into
      # the temporary schema, because that schema doesn't have a secrets table. The merge algorithm only operates
      # on the RBAC tables.
      def handle_public_key id, public_key
        policy_public_keys << [ id, public_key ]
      end
  
      # Update the public keys in the master schema, by comparing the public keys declared in the policy
      # with the existing public keys in the database.
      def store_public_keys
        policy_public_keys.each do |entry|
          id, public_key = entry
          resource = Resource[id]
          existing_secret = resource.last_secret
          ::Secret.create(resource: resource, value: public_key.strip) unless existing_secret && existing_secret.value == public_key
        end
      end
  
      def policy_public_keys
        @policy_public_keys ||= []
      end
    end
  end
end
