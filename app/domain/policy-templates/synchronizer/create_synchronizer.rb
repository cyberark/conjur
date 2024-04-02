# frozen_string_literal: true
require_relative '../base_template'

module PolicyTemplates
  class CreateSynchronizer < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
          - !policy
             id: synchronizer-<%= synchronizer_identifier %>
             body:
             - !host
                id: synchronizer-host-<%= synchronizer_identifier %>
                annotations:
                  authn/api-key: true
          - !policy
            id: synchronizer-installer-<%= synchronizer_identifier %>
            body:
              - !host
                id: synchronizer-installer-host-<%= synchronizer_identifier %>
                annotations:
                  authn/api-key: true
         
          - !grant
            role: !group synchronizer-hosts
            members:
              - !host synchronizer-<%= synchronizer_identifier %>/synchronizer-host-<%= synchronizer_identifier %>
         
          - !grant
            role: !group synchronizer-installer-hosts
            members:
              - !host synchronizer-installer-<%= synchronizer_identifier %>/synchronizer-installer-host-<%= synchronizer_identifier %>
       
          - !permit
            role: !host synchronizer-installer-<%= synchronizer_identifier %>/synchronizer-installer-host-<%= synchronizer_identifier %>
            privileges: [ update ]
            resources: !host synchronizer-<%= synchronizer_identifier %>/synchronizer-host-<%= synchronizer_identifier %>
      TEMPLATE
    end
  end
end