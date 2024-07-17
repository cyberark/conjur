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
      policies_cache = EffectivePolicy::PolicyTree::PolicyCache.new(root_pol_par_identifier, resources)
      grants_cache = EffectivePolicy::PolicyTree::GrantCache.new(policies_cache)

      # reducing provided policies to the policy tree
      resources.each do |res|
        par_pol = get_parent_policy(policies_cache, res)
        make_and_store_tree_elem(policies_cache, par_pol, res) unless root_policy?(res)
        make_and_store_permits(policies_cache, par_pol, res)
        make_and_store_grants(policies_cache, grants_cache, res)
      end

      if pol_identifier == 'root'
        policies_cache[""].sort_body
      else
        [policies_cache[pol_identifier]]
      end
    end

    private

    def root_policy?(res)
      res.resource_id == "#{res.account}:policy:root"
    end

    def get_parent_policy(policies_cache, res)
      policies_cache.get_or_init(policies_cache.parent_identifier(res.identifier))
    end

    def make_and_store_tree_elem(policies_cache, par_pol, res)
      tree_elem = make_tree_elem(policies_cache, res)
      add_to_policy(par_pol, *tree_elem)
      tree_elem
    end

    def make_and_store_permits(policies_cache, par_pol, res)
      permissions_with_proper_id = res.permissions.map do |perm|
        perm[:proper_role_id] = policies_cache.id(identifier(perm[:role_id]))
        perm[:proper_resource_id] = policies_cache.id(identifier(perm[:resource_id]))
        perm
      end
      permits = make_permits(permissions_with_proper_id)
      add_to_policy(par_pol, *permits)
    end

    def par_pol_identifier(identifier)
      last_slash_idx = identifier.rindex("/")
      parent_identifier = last_slash_idx.nil? ? "" : identifier[0, last_slash_idx]
      parent_identifier == 'root' ? '' : parent_identifier
    end

    def make_tree_elem(policies_cache, res)
      res_with_id = {
        identifier: policies_cache.id(res.identifier),
        parent_identifier: policies_cache.parent_identifier(res.identifier),
        res: res
      }
      if policy?(res.kind)
        initial_pol = policies_cache.get_or_init(res.identifier)
        enhance_policy(initial_pol, res_with_id)
      else
        make_policy_tree_elem(policies_cache, res_with_id)
      end
    end

    def add_to_policy(par_pol, *tree_elem)
      kind_elems = par_pol.value["body"] ||= []
      kind_elems.append(*tree_elem)
    end

    def make_policy_tree_elem(policies_cache, res_with_id)
      res = res_with_id[:res]
      case res.kind.tr('_', '-')
      when 'group', 'layer'
        make_group_or_layer(res_with_id)
      when 'host'
        make_host(res_with_id)
      when 'host-factory'
        layers = res.role.layers.map { |layer| tag('layer', policies_cache.id(identifier(layer.role_id)).to_s) }
        make_host_factory(res_with_id, layers)
      when 'user'
        make_user(res_with_id)
      when 'variable'
        make_variable(res_with_id)
      when 'webservice'
        make_webservice(res_with_id)
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
      par_pol_identifier = policies_cache.parent_identifier(role_identifier)
      # it might happen for queries with max depth that the parent of the role
      # was filtered out due to it's depth and we would wrongly assume that the
      # identifier of this role contains '/' and we would create a grant for a
      # role with slash
      par_pol = policies_cache.get_or_init(par_pol_identifier)
      add_to_policy(par_pol, *grant)
    end
  end
end
