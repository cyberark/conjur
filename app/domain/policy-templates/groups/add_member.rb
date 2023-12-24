# frozen_string_literal: true
require_relative '../base_template'

module PolicyTemplates
  class AddMemberToGroup < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
          - !grant
            role: !group <%= id %>
            member:          
              - !<%= kind %> <%= member_id %>        
      TEMPLATE
    end
  end
end