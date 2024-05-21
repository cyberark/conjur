# frozen_string_literal: true
require 'securerandom'
require 'sequel'

class Edge < Sequel::Model

  include HostAuthentication

  EDGE_HOST_PATTERN = "ACCOUNT:host:edge/edge-IDENTIFIER/edge-host-IDENTIFIER"
  EDGE_INSTALLER_HOST_PATTERN = "ACCOUNT:host:edge/edge-installer-IDENTIFIER/edge-installer-host-IDENTIFIER"
    class << self

    def new_edge(**values)
      raise ArgumentError, 'max allowed edges not provided' unless values[:max_edges]
      # extract max_edges from values and delete it from the data to be inserted
      max_edges = values.delete(:max_edges)
      raise ArgumentError, 'Edge name is not provided' unless values[:name]
      values[:id] ||= SecureRandom.uuid
      begin
        # Acquire the lock on the table (lock is released automatically at the end of the transaction)
        Sequel::Model.db.execute("LOCK TABLE edges IN ACCESS EXCLUSIVE MODE NOWAIT")
        table_size = Edge.count
        # Add a check for the maximum allowed limit
        raise ApplicationController::UnprocessableEntity, "Edge number exceeded max edge allowed #{max_edges}" unless table_size < max_edges.to_i
        Edge.insert(**values)
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("edge", values[:name])
      end
    end

    def get_by_hostname(hostname)
      Edge.where(id: hostname_to_id(hostname)).first || raise(Exceptions::RecordNotFound.new(hostname,
                                                                message: "Edge for host #{hostname} not found"))
    end

    def get_name_by_hostname(hostname)
      begin
        get_by_hostname(hostname).name
      rescue Exceptions::RecordNotFound
        ""  # Return empty string in case the edge instance is not in DB
      end
    end

    def hostname_to_id(hostname)
      regex = Regexp.new(EDGE_HOST_PATTERN.sub("ACCOUNT", '\w+').gsub("IDENTIFIER","(.+)"))
      hostname.match(regex)&.captures&.first
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

  def get_edge_host_name(account)
    EDGE_HOST_PATTERN.sub("ACCOUNT", account).gsub("IDENTIFIER", self.id)
  end

  def get_edge_installer_host_name(account)
    EDGE_INSTALLER_HOST_PATTERN.sub("ACCOUNT", account).gsub("IDENTIFIER", self.id)
  end

  def get_installer_token(account, request)
    installer_host_full_name = self.get_edge_installer_host_name(account)
    get_access_token(account, installer_host_full_name, request)
  end

end
