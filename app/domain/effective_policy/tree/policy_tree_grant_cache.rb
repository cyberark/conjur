# frozen_string_literal: true

module EffectivePolicy
  module PolicyTree
    class GrantCache
      include(EffectivePolicy::ResPathing)
      include(EffectivePolicy::PolicyTree::Tagging)
      include(EffectivePolicy::PolicyTree::TagMaking)

      attr_reader :grants

      def initialize(policies_cache)
        @grants = {}
        @policies_cache = policies_cache
      end

      def to_s
        @grants.to_s
      end

      def add(role_kind, role_identifier, res_kind, res_identifier)
        member_identifier = "/#{res_identifier}"
        grant = get_or_init(role_kind, role_identifier)
        grant.value["members"] << tag(res_kind, member_identifier)
        grant
      end

      private

      def get_or_init(role_kind, role_identifier)
        @grants[role_identifier] ||= make_initial_grant(role_kind, @policies_cache.id(role_identifier))
      end
    end
  end
end
