# frozen_string_literal: true
require_relative '../base_template'

module PolicyTemplates
  class CreateEdge < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
          - !policy
             id: edge-<%= edge_identifier %>
             body:
             - !host
                id: edge-host-<%= edge_identifier %>
                annotations:
                  authn/api-key: true
          - !policy
            id: edge-installer-<%= edge_identifier %>
            body:
              - !host
                id: edge-installer-host-<%= edge_identifier %>
                annotations:
                  authn/api-key: true
         
          - !grant
            role: !group edge-hosts
            members:
              - !host edge-<%= edge_identifier %>/edge-host-<%= edge_identifier %>
         
          - !grant
            role: !group edge-installer-group
            members:
              - !host edge-installer-<%= edge_identifier %>/edge-installer-host-<%= edge_identifier %>
       
          - !permit
            role: !host edge-installer-<%= edge_identifier %>/edge-installer-host-<%= edge_identifier %>
            privileges: [ update ]
            resources: !host edge-<%= edge_identifier %>/edge-host-<%= edge_identifier %>
      TEMPLATE
    end
  end
end
