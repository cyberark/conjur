# frozen_string_literal: true
require 'securerandom'
require 'sequel'

class Edge < Sequel::Model

    class << self

    EDGE_HOST_PREFIX = 'edge-host-'

    def new_edge(**values)
      values[:id] ||= SecureRandom.uuid
      Edge.insert(**values)
    end

    def record_edge_access(host_name, data, ip)
      edge_record = Edge.get_by_hostname(host_name) || raise(Exceptions::RecordNotFound)
      edge_record.ip = ip
      edge_record.version = data['edge_version'] if data['edge_version']
      sync_time = Time.at(data['edge_statistics']['last_synch_time']) # This field is required
      edge_record.last_sync = sync_time
      edge_record.installation_date = sync_time unless edge_record.installation_date
      edge_record.platform = data['edge_container_type'] if data['edge_container_type']

      edge_record.save
    end

    def get_by_hostname(hostname)
      Edge.where(id: hostname_to_id(hostname)).first
    end

    def hostname_to_id(hostname)
      regex = /(?<=#{EDGE_HOST_PREFIX})(.+)/
      hostname.match(regex)&.captures&.first
    end

    def id_to_hostname(id)
      EDGE_HOST_PREFIX + id
    end
  end
end
