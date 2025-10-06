# frozen_string_literal: true

module EffectivePolicy
  module PolicyTree
    module TagValue
      def prepare_id(id)
        { "id" => id }
      end

      def init_res_values_with_owner_and_anns(res_with_id)
        res = res_with_id[:res]
        prepare_id(res_with_id[:identifier])
          .merge(prepare_owner(res_with_id))
          .merge(prepare_annotations(res))
      end

      def prepare_host_factory_layers(layers)
        layers.empty? ? {} : { "layers" => pure_str_tag(layers) }
      end

      def prepare_host_restricted_to(res)
        restricted_to = res.role.restricted_to.map(&:to_s)
        restricted_to.empty? ? {} : { "restricted_to" => pure_str_tag(restricted_to) }
      end

      def prepare_var_kind(anns = {})
        var_kind = anns.delete("conjur/kind")
        var_kind.nil? ? {} : { "kind" => var_kind }
      end

      def prepare_var_mime_type(anns)
        var_mime_type = anns.delete("conjur/mime_type")
        var_mime_type.nil? ? {} : { "mime_type" => var_mime_type }
      end

      def prepare_owner(res_with_id)
        res = res_with_id[:res]
        owner_identifier = identifier(res.owner_id)
        owner_kind = kind(res.owner_id)
        owner_id = "/#{owner_identifier}"

        # we do not want to create owner value
        # if we the policy in which the resource is created is the owner
        # or we are in top of the tree and admin user is the owner as it is handled by convention
        # during loading a policy
        return {} if owner_has_default_policy_or_is_admin?(res, res_with_id[:parent_identifier])

        owner = tag(owner_kind, owner_id)
        { "owner" => owner }
      end

      def build_annotations(res)
        res.annotations.each_with_object({}) do |ann, result|
          ann_key = ann.values[:name]
          ann_val = ann.values[:value]
          result[ann_key.to_s] = ann_val.to_s
        end
      end

      def prepare_annotations_hash(anns)
        anns.empty? ? {} : { "annotations" => anns }
      end

      def prepare_annotations(res)
        anns = build_annotations(res)
        prepare_annotations_hash(anns)
      end

      private

      def owner_has_default_policy_or_is_admin?(res, parent_identifier)
        (policy?(kind(res.owner_id)) && parent_identifier == identifier(res.owner_id)) ||
          (parent_identifier == '' && res.owner_id == "#{res.account}:user:admin")
      end
    end
  end
end
