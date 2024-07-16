# frozen_string_literal: true

require_relative('pathing/res_pathing')
require_relative('pathing/user_pathing')
require_relative('tree/policy_tree_permit')
require_relative('tag/policy_tree_tag')
require_relative('tag/policy_tree_tag_making')

module EffectivePolicy
  class BuildPolicyTree
    include(EffectivePolicy::ResPathing)
    include(EffectivePolicy::PolicyTree::Permit)
    include(EffectivePolicy::PolicyTree::Tagging)
    include(EffectivePolicy::PolicyTree::TagMaking)

    def call(pol_identifier = "", resources = [])
      root_pol_par_identifier = par_pol_identifier(pol_identifier)
      policies_cache = EffectivePolicy::PolicyTree::PolicyCache.new(root_pol_par_identifier)
      grants_cache = EffectivePolicy::PolicyTree::GrantCache.new

      # reducing provided policies to the policy tree
      resources.each do |res|
        # we ignore 'root' policy and assign its children to the top layer in yaml
        next if res.identifier == 'root'

        par_pol = get_parent_policy(policies_cache, res)
        make_and_store_tree_elem(policies_cache, par_pol, res)
        make_and_store_permits(par_pol, res)
        make_and_store_grants(policies_cache, grants_cache, res)
      end

      if pol_identifier == 'root'
        policies_cache[""].sort_body
      else
        [policies_cache[pol_identifier]]
      end
    end

    private

    def get_parent_policy(policies_cache, res)
      policies_cache.get_or_init(par_pol_identifier(res.identifier))
    end

    def make_and_store_tree_elem(policies_cache, par_pol, res)
      tree_elem = make_tree_elem(policies_cache, res)
      add_to_policy(par_pol, *tree_elem)
      tree_elem
    end

    def make_and_store_permits(par_pol, res)
      permits = make_permits(res.permissions)
      add_to_policy(par_pol, *permits)
    end

    def par_pol_identifier(identifier)
      parent_identifier =  parent_identifier(identifier)
      parent_identifier == 'root' ? '' : parent_identifier
    end

    def make_tree_elem(policies_cache, res)
      if policy?(res.kind)
        initial_pol = policies_cache.get_or_init(res.identifier)
        enhance_policy(initial_pol, res)
      else
        make_policy_tree_elem(res)
      end
    end

    def add_to_policy(par_pol, *tree_elem)
      kind_elems = par_pol.value["body"] ||= []
      kind_elems.append(*tree_elem)
    end

    def make_policy_tree_elem(res)
      case res.kind.tr('_', '-')
      when 'group', 'layer'
        make_group_or_layer(res)
      when 'host'
        make_host(res)
      when 'host-factory'
        make_host_factory(res)
      when 'user'
        make_user(res)
      when 'variable'
        make_variable(res)
      when 'webservice'
        make_webservice(res)
      else
        raise("unsupported kind #{res.kind} for #{res.identifier}")
      end
    end

    def make_and_store_grants(policies_cache, grants_cache, res)
      res_roles = res.values[:role_ids] || []

      res_roles.each do |role_full_id|
        role_identifier = identifier(role_full_id)
        role_kind = kind(role_full_id)
        grant = grants_cache.add(role_kind, role_identifier, res.kind, res.identifier)

        # if there is just one member it means we have just created the grant
        # and we need to add it to proper policy
        add_grant_to_parent_of_role(policies_cache, role_identifier, grant) if grant.value["members"].one?
      end
    end

    def add_grant_to_parent_of_role(policies_cache, role_identifier, grant)
      par_pol_identifier = parent_identifier(role_identifier)
      par_pol = policies_cache.get_or_init(par_pol_identifier)

      add_to_policy(par_pol, *grant)
    end
  end
end
