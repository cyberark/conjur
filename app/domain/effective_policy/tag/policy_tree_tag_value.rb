# frozen_string_literal: true

module EffectivePolicy
  module PolicyTree
    module TagValue
      def prepare_id(id)
        { "id" => id }
      end

      def init_res_values_with_owner_and_anns(res)
        prepare_id(id(res.identifier))
          .merge(prepare_owner(res))
          .merge(prepare_annotations(res))
      end

      def prepare_host_factory_layers(res)
        layers = res.role.layers.map { |layer| tag('layer', id(identifier(layer.role_id)).to_s) }
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

      def prepare_owner(res)
        owner_identifier = identifier(res.owner_id)
        owner_kind = kind(res.owner_id)
        owner_id = "/#{owner_identifier}"
        return {} if owner_has_default_policy_or_is_admin?(res.identifier, owner_kind, owner_identifier, owner_id)

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

      def owner_has_default_policy_or_is_admin?(res_identifier, owner_kind, owner_identifier, owner_id)
        (policy?(owner_kind) && parent_identifier(res_identifier) == owner_identifier) || owner_id == '/admin'
      end
    end
  end
end
