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
