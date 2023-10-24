# frozen_string_literal: true
require_relative '../base_template'

module PolicyTemplates
  class DeleteEdge < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
        - !delete
          record: !host edge-<%= edge_identifier %>/edge-host-<%= edge_identifier %>

        - !delete
          record: !policy edge-<%= edge_identifier %>
        
        - !delete
          record: !host edge-installer-<%= edge_identifier %>/edge-installer-host-<%= edge_identifier %>

        - !delete
          record: !policy edge-installer-<%= edge_identifier %>
      
      TEMPLATE
    end
  end
end
