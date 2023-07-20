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

    def get_by_hostname(hostname)
      Edge.where(id: hostname_to_id(hostname)).first || raise(Exceptions::RecordNotFound.new(hostname,
                                                                message: "Edge for host #{hostname} not found"))
    end

    def hostname_to_id(hostname)
      regex = /(?<=#{EDGE_HOST_PREFIX})(.+)/
      hostname.match(regex)&.captures&.first
    end

    def id_to_hostname(id)
      EDGE_HOST_PREFIX + id
    end
  end

  def record_edge_access(data, ip)
    self.ip = ip
    self.version = data['edge_version'] if data['edge_version']
    sync_time = Time.at(data['edge_statistics']['last_synch_time']) # This field is required
    self.last_sync = sync_time if sync_time.to_i > 0
    self.platform = data['edge_container_type'] if data['edge_container_type']

    self.save
  end
end
