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
