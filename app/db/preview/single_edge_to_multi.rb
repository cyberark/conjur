# frozen_string_literal: true
#TODO: delete once single edge users are migrated to multi
module DB
  module Preview
    class SingleEdgeToMulti
      def find_single_host_id
        edge_host = Role.where(:role_id.like('conjur:host:edge/%edge-host-%')).first
        edge_installer = Role.where(:role_id.like('conjur:host:edge/%edge-installer-host-%')).first
        return get_edge_id(edge_host.role_id) if edge_host && edge_installer
        nil
      end

      def get_edge_id(hostname)
        regex = /(?<=#{'edge-host-'})(.+)/
        hostname.match(regex)&.captures&.first
      end
    end
  end
end