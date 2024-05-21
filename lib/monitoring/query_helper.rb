require 'singleton'

module Monitoring
  class QueryHelper
    include Singleton

    DYNAMIC_VARIABLE_PREFIX = "data/dynamic/"

    def policy_resource_counts
      counts = {}
      kind = ::Sequel.function(:kind, :resource_id)
      Resource.group_and_count(kind).each do |record|
        counts[record[:kind]] = record[:count]
      end
      counts
    end

    def policy_visible_resource_counts
      counts = {}
      counts["issuers"] = Issuer.where(account: 'conjur').count
      counts["dynamic-secrets"] = Resource.where(Sequel.like(:resource_id, 'conjur:variable:' + Issuer::DYNAMIC_VARIABLE_PREFIX + '%')).count
      counts["secrets"] = Resource.where(Sequel.like(:resource_id, '%conjur:variable:data/%')).count
      counts["workloads"] = Resource.where(Sequel.like(:resource_id, '%conjur:host:data/%')).count
      counts["users"] = Resource.where(Sequel.like(:resource_id, '%conjur:user:%')).count
      counts["host-factory"] = HostFactoryToken.count

      synchronizer_policy = "conjur:policy:synchronizer"
      synchronizerPolicyResource = Resource.find(resource_id: synchronizer_policy)
      is_pam_self_hosted = !synchronizerPolicyResource.nil?
      if is_pam_self_hosted
        counts["pam-self-hosted"] = 1
      else
        counts["pam-self-hosted"] = 0
      end

      counts
    end

    def policy_role_counts
      counts = {}
      kind = ::Sequel.function(:kind, :role_id)
      Role.group_and_count(kind).each do |record|
        counts[record[:kind]] = record[:count]
      end
      counts
    end
  end
end
