# frozen_string_literal: true

module EffectivePolicy
  module PolicyTree
    class PolicyCache
      include(EffectivePolicy::ResPathing)
      include(EffectivePolicy::PolicyTree::Tagging)
      include(EffectivePolicy::PolicyTree::TagMaking)

      attr_reader :policies

      @policies = {}

      def initialize(root_pol_par_identifier = "")
        @policies = { root_pol_par_identifier => make_initial_policy(root_pol_par_identifier) }
      end

      def to_s
        @policies.to_s
      end

      def key?(identifier)
        @policies.key?(identifier)
      end

      def add(identifier, policy)
        @policies[identifier] = policy
      end

      alias []= :add

      def [](identifier)
        @policies[identifier]
      end

      def get_or_init(identifier)
        @policies[identifier] ||= make_initial_policy(id(identifier))
      end
    end
  end
end
