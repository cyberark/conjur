require 'open3'

#Before do
  #ENV['TEST_ENV_NUMBER'] = ""
#end

When(/^I retrieve an API key for user "([^"]*)" using conjurctl$/) do |user_id|
  command = "conjurctl role retrieve-key #{user_id}"
  @conjurctl_stdout, @conjurctl_stderr, = Open3.capture3(command)
end

Then(/^the API key is correct$/) do
  expect(@conjurctl_stdout).to eq("#{Credentials['cucumber:user:admin'].api_key}\n")
end

Then(/^the stderr includes the error "([^"]*)"$/) do |error|
  expect(@conjurctl_stderr).to include(error)
end

Given(/^I create an account with the name "(.*?)" and the password "(.*?)" using conjurctl/) do |name, password|
  #ENV['TEST_ENV_NUMBER'] = ""
  command = "echo -n '#{password}' | \
    conjurctl account create --password-from-stdin --name #{name}"
  @conjurctl_stdout, @conjurctl_stderr, = Open3.capture3(command)
end
