require 'open3'

When(/^I retrieve an API key for user "([^"]*)" using conjurctl$/) do |user_id|
  command = "(conjurctl role retrieve-key #{user_id} > /tmp/admin-key.txt)"    
  #command = "conjurctl role retrieve-key #{user_id}"  
  @conjurctl_stdout, @conjurctl_stderr, = Open3.capture3(command)
  #@conjurctl_stdout = File.read("/tmp/admin-key.txt")
  @adam_stdout = File.read("/tmp/admin-key.txt")
  puts "SIMPLECOV_DEBUG1-@conjurctl_stdout: #{@conjurctl_stdout}"
  puts "SIMPLECOV_DEBUG2-@adam_stdout: #{@adam_stdout}"
end

Then(/^the API key is correct$/) do
  #@conjurctl_stdout = File.read("/tmp/admin-key.txt") #added ao
  #@adam_stdout = File.read("/tmp/admin-key.txt") #added ao
  puts "SIMPLECOV_DEBUG3-@adam_stdout: #{@adam_stdout}"
  expect(@adam_stdout).to eq("#{Credentials['cucumber:user:admin'].api_key}\n")
end

Then(/^the stderr includes the error "([^"]*)"$/) do |error|
  expect(@conjurctl_stderr).to include(error)
end

Given(/^I create an account with the name "(.*?)" and the password "(.*?)" using conjurctl/) do |name, password|
  command = "echo -n '#{password}' | \
    conjurctl account create --password-from-stdin --name #{name}"
  @conjurctl_stdout, @conjurctl_stderr, = Open3.capture3(command)
end
