# frozen_string_literal: true
require_relative '../base_template'

module PolicyTemplates
  class RemoveMemberFromGroup < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
          - !revoke
            role: !group <%= id %>
            member:          
              - !<%= kind %> <%= member_id %>        
      TEMPLATE
    end
  end
end