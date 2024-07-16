# frozen_string_literal: true

module EffectivePolicy
  module PolicyTree
    module Permit

      def make_permits(permissions = [])
        permits_cache = {}
        # reducing permissions to permits and combining privileges in an array
        permissions.each_with_object([]) do |perm, permits|

          permit = get_or_init(permits_cache, perm)

          privileges_arr = get_privileges_arr(permit)

          # first privilege entry for the resource
          permits << permit if privileges_arr.empty?

          # adding new privilege to the array inside a permit
          privileges_arr << perm.values[:privilege]
        end
      end

      private

      def get_or_init(permits_cache, perm)
        role_full_id = perm[:role_id]
        res_full_id = perm[:resource_id]

        permit_key = role_full_id + res_full_id

        role_kind = kind(role_full_id)
        role_id = perm[:proper_role_id]
        res_kind = kind(res_full_id)
        res_id = perm[:proper_resource_id]

        permits_cache[permit_key] ||= make_initial_permit(role_kind, role_id, res_kind, res_id)
      end

      def get_privileges_arr(permit = {})
        # tag {
        #   "value" => {
        #     "privileges" => tag {
        #       value => []
        #     }
        #   }
        # }
        permit.value["privileges"].value
      end
    end
  end
end
