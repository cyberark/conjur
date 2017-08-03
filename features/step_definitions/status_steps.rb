When(/^I visit the Conjur CE status page$/) do
  visit('/')
end

And(/^I should see "([^"]*)" on the status page$/) do |term|
  page.should have_content("#{term}")
end

And(/^I should see the current Conjur CE version$/) do
  page.should have_content("Details:")
  page.should have_content("Version #{ENV["POSSUM_VERSION_APPLIANCE"]}")
end
