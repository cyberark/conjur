# frozen_string_literal: true
require 'securerandom'
require 'sequel'
require 'sequel/plugins/uuid'

Sequel::Model.plugin :uuid
class Edge < Sequel::Model
  plugin :uuid, field: :id

  def before_create
    self.id ||= SecureRandom.uuid
    super
  end

  class << self

    EDGE_HOST_PREFIX = 'edge-host-'

    def get_by_hostname(hostname)
      Edge.where(id: hostname_to_id(hostname)).first
    end

    def hostname_to_id(hostname)
      regex = /(?<=#{EDGE_HOST_PREFIX})(.+)/
      captures = hostname.match(regex)&.captures
      captures.first
    end

    def id_to_hostname(id)
      EDGE_HOST_PREFIX + id
    end
  end
end
