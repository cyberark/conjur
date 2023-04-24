require 'spec_helper'

describe HostsController, :type => :request do
  let(:account) { "rspec" }
  let(:user_id) {"#{account}:user:admin"}
  let(:host_name) {"edge-host-6d50922eedee3fa58b8f20f675fc11a3"}
  let(:id) {"edge/#{host_name}/#{host_name}"}
  let(:host_id) {"#{account}:host:#{id}"}

  before do
    Slosilo["authn:#{account}"] ||= Slosilo::Key.new
  end

  let(:token_auth_header) do
    bearer_token = Slosilo["authn:#{account}"].signed_token(@current_user.login)
    token_auth_str =
      "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
    { 'HTTP_AUTHORIZATION' => token_auth_str }
  end

  context "Hosts creds in DB" do
    include_context "create host"
    let(:the_host) { create_host(id) }

    it "Returned API key equals to key in DB" do
      @current_user = Role.find_or_create(role_id: user_id)
      # add user to Conjur_Cloud_Admins group
      Role.create(role_id: "#{account}:group:Conjur_Cloud_Admins")
      RoleMembership.create(role_id: "#{account}:group:Conjur_Cloud_Admins", member_id: user_id, admin_option: true, ownership:true)
      #add edge-hosts to edge/edge-hosts group
      Role.create(role_id: "#{account}:group:edge/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: the_host.role_id, admin_option: true, ownership:true)

      get("/edge/host/#{account}/#{host_name}", env: token_auth_header)
      expect(response.code).to eq("200")
      host_cred = Credentials.where(:role_id.like("%"+host_id)).all
      key = host_cred[0][:api_key].unpack("H*")[0]
      expected = "#{host_id}-#{key}"
      response_body = response.body
      res_decoded = Base64.strict_decode64(response_body)
      expect(expected).to eq(res_decoded)
    end
  end
end