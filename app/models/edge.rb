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
