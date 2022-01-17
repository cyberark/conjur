# This allows to you reference some global variables such as `$?` using less 
# cryptic names like `$CHILD_STATUS`
require 'English'

When(/^I load a large policy with POST$/) do
  # Generate a large policy with 1000 variables, sampled from
  # an example PAS synchronizer policy
  policy_body = "- &my-variables\n" + [*1..1000].map do |i|
    <<-POLICY
  - !variable
    id: epv_safe_#{i}/password
    annotations:
      cyberark-vault: 'true'
    POLICY
  end.join("\n")

  path = '/policies/cucumber/policy/dev/db'

  try_request true do
    post_json path, policy_body
  end
end

When('I use curl to load a policy with special characters and no content type') do
  # Policy with special characters, sampled from a PAS synchronizer test policy
  policy_body = <<~POLICY
    - !variable
      id: AccountWithSpecialCharacters~!@#$%^&(){}[]-+=,Name/password
  POLICY

  auth_token = current_user_credentials.dig(:headers, :authorization)

  url_path = '/policies/cucumber/policy/dev/db'

  # `--no-buffer` allows to close the pipe in popen without getting a curl error
  # `--output ...` prevents curl from trying to write to stdout, causing an io error
  command = <<~COMMAND
    curl --silent \
      --no-buffer \
      --fail \
      --output /dev/null \
      --header 'Content-Type:' \
      --header 'Authorization: #{auth_token}' \
      --data-binary '@-' \
      #{full_conjur_url(url_path)}
  COMMAND

  IO.popen(command, "r+") do |pipe|
    pipe.puts(policy_body)
    pipe.close_write
  end

  @command_result = $CHILD_STATUS.success?
end

When(/^I migrate the db/) do
  system("rake db:migrate")
end

Then('the command is successful') do
  expect(@command_result).to be(true)
end
