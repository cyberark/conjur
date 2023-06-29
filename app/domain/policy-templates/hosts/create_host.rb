# frozen_string_literal: true
require_relative '../base_template'

module PolicyTemplates
  class CreateHost < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
        - !host
          id: <%= id %>
          <% unless annotations.nil? ||  annotations.empty? %>
          annotations:
          <%- annotations.each do |key, value| -%>
            <%= key %>: <%= value %>
          <%- end -%>
          <% end %>
        <% unless groups.nil? ||  groups.empty?%>
        <% groups.each do |group| %>  
        - !grant
          role: !group <%= group %>
          member: !host <%= id %>
        <% end %>
        <% end %>
        <% unless layers.nil? || layers.empty?%>
        <% layers.each do |layer| %>  
        - !grant
          role: !layer <%= layer %>
          member: !host <%= id %>
        <% end %>
        <% end %>
      TEMPLATE
    end
  end
end