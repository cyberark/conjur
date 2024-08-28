# frozen_string_literal: true

def apply_policy(policy:, policy_branch: 'root', role: 'admin', account: 'rspec', action: :post)
  # Setup in case this is the first run
  Slosilo["authn:#{account}"] ||= Slosilo::Key.new
  Role.find_or_create(role_id: "#{account}:user:#{role}")

  # Apply policy
  send(
    action,
    "/policies/#{account}/policy/#{policy_branch}",
    env: {
      'HTTP_AUTHORIZATION' => access_token_for(role),
      'RAW_POST_DATA' => policy
    }
  )
end

def validate_policy(policy:, policy_branch: 'root', role: 'admin', account: 'rspec', action: :post)
  # Setup in case this is the first run
  Slosilo["authn:#{account}"] ||= Slosilo::Key.new
  Role.find_or_create(role_id: "#{account}:user:#{role}")

  # Dry-run the policy
  send(
    action,
    "/policies/#{account}/policy/#{policy_branch}?dryRun=true",
    env: {
      'HTTP_AUTHORIZATION' => access_token_for(role),
      'RAW_POST_DATA' => policy
    }
  )
end
