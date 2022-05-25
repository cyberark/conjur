require 'singleton'

module Monitoring
  class QueryHelper
    include Singleton

    def policy_resource_counts()
      counts = {}
      kind = ::Sequel.function(:kind, :resource_id)
      Resource.group_and_count(kind).each do |record|
        counts[record[:kind]] = record[:count]
      end
      counts
    end

  end
end
