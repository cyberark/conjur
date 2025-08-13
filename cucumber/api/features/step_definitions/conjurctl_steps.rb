require 'open3'

When(/^I retrieve an API key for user "([^"]*)" using conjurctl$/) do |user_id|
  @conjurctl_stdout, @conjurctl_stderr, = Open3.capture3("conjurctl", "role", "retrieve-key", user_id)
end

Then(/^the API key is correct$/) do
  expect(@conjurctl_stdout).to eq("#{Credentials['cucumber:user:admin'].api_key}\n")
end

Then(/^the stderr includes the error "([^"]*)"$/) do |error|
  expect(@conjurctl_stderr).to include(error)
end

Given(/^I create an account with the name "(.*?)" and the password "(.*?)" using conjurctl/) do |name, password|
  Open3.popen3("conjurctl", "account", "create", "--password-from-stdin", "--name", name) do |stdin, stdout, stderr, wait_thr|
    stdin.write(password)
    stdin.close
    @conjurctl_stdout = stdout.read
    @conjurctl_stderr = stderr.read
    raise "Command failed with error: #{@conjurctl_stderr}" unless wait_thr.value.success?
  end
end
