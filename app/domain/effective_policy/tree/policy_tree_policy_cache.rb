# frozen_string_literal: true

module EffectivePolicy
  module PolicyTree
    class PolicyCache
      include(EffectivePolicy::ResPathing)
      include(EffectivePolicy::PolicyTree::Tagging)
      include(EffectivePolicy::PolicyTree::TagMaking)

      attr_reader :policies

      @policies = {}
      @parent_policies = {}
      @valid_policies = []

      def initialize(root_pol_par_identifier = "", resources = [])
        @policies = { root_pol_par_identifier => make_initial_policy(root_pol_par_identifier) }
        @parent_policies = { root_pol_par_identifier => nil }
        @valid_policies = resources.select { |res| policy?(kind(res.resource_id)) }.map(&:identifier)
        @valid_policies << root_pol_par_identifier
      end

      def to_s
        @policies.to_s
      end

      def key?(identifier)
        @policies.key?(identifier)
      end

      def add(identifier, policy)
        @policies[identifier] = policy
        @parent_policies[identifier] = parent_identifier(identifier)
      end

      alias []= :add

      def [](identifier)
        @policies[identifier]
      end

      def get_or_init(identifier)
        @policies[identifier] ||= make_initial_policy(id(identifier))
      end

      def id(str_id)
        str_id.delete_prefix(parent_identifier(str_id) + '/')
      end
      def parent_identifier(identifier)
        @parent_policies[identifier] ||= valid_parent_identifier(identifier)
      end

      private

      def valid_parent_identifier(identifier)
        path = identifier.split('/')
        until path.empty? do
          path.pop
          parent = path.join('/')
          return parent if @valid_policies.include?(parent)
        end
        path == 'root' ? '' : path
      end
    end
  end
end
