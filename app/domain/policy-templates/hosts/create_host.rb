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
      TEMPLATE
    end
  end
end