# frozen_string_literal: true

require_relative('./policy_tree_tag_value')

module EffectivePolicy
  module PolicyTree
    module TagMaking
      include(EffectivePolicy::PolicyTree::TagValue)

      def make_initial_policy(pol_id)
        # - !policy
        #   id: <name>
        #   body:
        #     []
        values = prepare_id(pol_id)
          .merge("body" => [])

        tag(:policy, values)
      end

      def enhance_policy(initial_pol, res_with_id)
        # - !policy
        #   id: <name>
        #   owner: !<kind-of-role> <role-name>
        #   annotations:
        #     <key>: <value>
        #   body:
        #     [keeps, existing, entries]
        values = init_res_values_with_owner_and_anns(res_with_id)
          .merge(initial_pol.value)

        initial_pol.value = values
        initial_pol
      end

      def make_user(res_with_id)
        # - !user
        #   id: <name>
        #   owner: !<kind-of-role> <role-name>
        #   annotations:
        #     <key>: <value>
        #   restricted_to: <network range>
        res = res_with_id[:res]
        values = init_res_values_with_owner_and_anns(res_with_id)
          .merge(prepare_host_restricted_to(res))

        tag(res.kind, values)
      end

      def make_group_or_layer(res_with_id)
        # - !group
        #   id: <group-name>
        #   owner: !<kind-of-role> <role-name>
        #   annotations:
        #     editable: true | false
        # - !layer
        #   id: <name>
        #   owner: !<kind-of-role> <role-name>
        #   annotations:
        #     <key>: <value>
        res = res_with_id[:res]
        values = init_res_values_with_owner_and_anns(res_with_id)

        tag(res.kind, values)
      end

      def make_host(res_with_id)
        # - !host
        #   id: <name>
        #   owner: !<kind-of-role> <role-name>
        #   annotations:
        #     <key>: <value>
        #   restricted_to: <network range>
        res = res_with_id[:res]
        values = init_res_values_with_owner_and_anns(res_with_id)
          .merge(prepare_host_restricted_to(res))

        tag(res.kind, values)
      end

      def make_host_factory(res_with_id, layers)
        # - !host-factory
        #   id: <name>
        #   owner: !<kind-of-role> <role-name>
        #   layers: [ !layer <layer-name>, ... ]
        #   annotations:
        #     <key>: <value>
        res = res_with_id[:res]
        values = prepare_id(res_with_id[:identifier])
          .merge(prepare_owner(res_with_id))
          .merge(prepare_host_factory_layers(layers))
          .merge(prepare_annotations(res))

        tag(res.kind, values)
      end

      def make_variable(res_with_id)
        # - !variable
        #   id: <name>
        #   kind: <description>
        #   mime_type:
        #   annotations:
        #     <key>: <value>

        # kind and mime_type are stored in the annotations
        # key prefix is 'conjur/'
        res = res_with_id[:res]
        anns = build_annotations(res)
        values = prepare_id(res_with_id[:identifier])
          .merge(prepare_var_kind(anns))
          .merge(prepare_var_mime_type(anns))
          .merge(prepare_annotations_hash(anns))

        tag(res.kind, values)
      end

      def make_webservice(res_with_id)
        # - !webservice
        #   id: <name>
        #   owner: !<kind-of-role> <role-name>
        res = res_with_id[:res]
        values = init_res_values_with_owner_and_anns(res_with_id)

        tag(res.kind, values)
      end

      def make_initial_permit(role_kind, role_id, res_kind, res_id)
        # - !permit
        #   role: !<kind-of-role> <role-name>
        #   privileges: [x,y,z]
        #   resource: !<kind-of-resource> <resource-name>
        tag(:permit,
            "role" => tag(role_kind, role_id),
            "privileges" => pure_str_tag([]),
            "resource" => tag(res_kind, res_id))
      end

      def make_initial_grant(role_kind, role_id)
        # - !grant
        #   role: !<kind-of-role> <role-name>    #Granting role.
        #   members:                             #Recipient roles.
        #   - !<kind-of-role> <role-name>
        #   - !<kind-of-role> <role-name>
        tag(:grant,
            "role" => tag(role_kind, role_id),
            "members" => [])
      end
    end
  end
end
