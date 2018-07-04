# frozen_string_literal: true

Given(/^I show the ([\w_]+) "([^"]*)"$/) do |kind, id|
  invoke do
    data = conjur_api.resource(make_full_id(kind, id)).attributes
    data['members'] = begin
      conjur_api.role(make_full_id(kind, id)).members
    rescue RestClient::NotFound
      []
    end
    data
  end
end
