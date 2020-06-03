# frozen_string_literal: true

When(/^I load a policy from file "([^"]*)" using conjurctl/) do |filename|
  absolute_path = "#{File.dirname __FILE__}/../support/#{filename}"
  rake_task = ["rake", "policy:load[cucumber, #{absolute_path}]"]
  system(*rake_task)
end
