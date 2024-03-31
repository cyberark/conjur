require 'singleton'

module Monitoring
  class QueryHelper
    include Singleton

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
