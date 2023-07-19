require 'monitoring/query_helper'
require 'spec_helper'

describe Monitoring::QueryHelper, type: :request do
  let(:queryhelper) { Monitoring::QueryHelper.instance }

  let(:policies_url) { '/policies/rspec/policy/root' }

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  let(:token_auth_header) do
    bearer_token = Slosilo["authn:rspec"].signed_token(current_user.login)
    token_auth_str =
      "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
    { 'HTTP_AUTHORIZATION' => token_auth_str }
  end

  def headers_with_auth(payload)
    token_auth_header.merge({ 'RAW_POST_DATA' => payload })
  end

  before do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    post(policies_url, env: headers_with_auth('[!group test]'))
  end

  it 'returns policy resource counts' do
    resource_counts = queryhelper.policy_resource_counts
    expect(resource_counts['group']).to equal(1)
  end

  it 'returns policy role counts' do
    role_counts = queryhelper.policy_role_counts
    expect(role_counts['group']).to equal(1)
  end

end
