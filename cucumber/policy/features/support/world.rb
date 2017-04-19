module Possum
end

module FullId
  def make_full_id id
    tokens = id.split(":", 3)
    case tokens.length
    when 2
      tokens.unshift $possum_account
    when 3
      # pass
    else
      raise "Expected at least two tokens in #{id}"
    end
    tokens.join(":")
  end
end

class PossumClient
  include FullId
  
  require 'possum'
  
  attr_reader :username, :api_key, :client
  
  def initialize username, api_key
    @username = username
    @api_key = api_key
    @client = new_client
    @client.login $possum_account, username, api_key
  end
  
  def rotate_api_key id = nil
    if id
      id = make_full_id id
      @client.put("authn/cucumber/api_key?role=#{id}")
    else
      @client.put("authn/cucumber/api_key")
    end
  end

  def resource_show id
    id = make_full_id id
    @client.get "resources/#{id_path(id)}"
  end

  def resource_list options = {}
    params = options.inject([]) do |memo, entry|
      memo.push "#{CGI.escape entry[0].to_s}=#{CGI.escape entry[1].to_s}"
      memo
    end
    @client.get "resources/#{$possum_account}?#{params.join('&')}"
  end
  
  def resource_check id, privilege
    id = make_full_id id
    @client.get "resources/#{id_path(id)}?check&privilege=#{privilege}"
  end

  def resource_permitted_roles id, privilege
    id = make_full_id id
    @client.get "resources/#{id_path(id)}?permitted_roles&privilege=#{privilege}"
  end

  def role_show id
    id = make_full_id id
    @client.get "roles/#{id_path(id)}"
  end

  def policy_show id, version=nil
    params = if version
      "?version=#{version}"
    else
      ""
    end
    @client.get "policies/#{id_path(id)}#{params}"
  end

  def policy_load id, body
    @client.put "policies/#{id_path(id)}", body
  end

  def policy_extend id, body
    @client.post "policies/#{id_path(id)}", body
  end
    
  def secret_add id, value
    id = make_full_id id
    @client.post "secrets/#{id_path(id)}", value
  end

  def secret_fetch id
    id = make_full_id id
    @client.get "secrets/#{id_path(id)}"
  end

  def public_keys id
    # This one uses raw RestClient::Resource because it doesn't require authentication
    require 'rest-client'
    id = make_full_id id
    new_client.get "public_keys/#{id_path(id)}"
  end
  
  protected

  def new_client
    Possum::Client.new url: $possum_url
  end
  
  def id_path id
    id.gsub(':', '/')
  end
end

module PossumWorld
  include FullId
  
  attr_reader :result
  
  def invoke status = :ok, &block
    begin
      @result = yield
      raise "Expected invocation to be denied" unless status == :ok
      @result.tap do |result|
        puts result if @echo
      end
    rescue Possum::UnexpectedResponseError => e
      status = status.to_i if status.is_a?(String)
      raise e unless status == e.response.status
    end
  end

  def load_bootstrap_policy policy
    load_policy "bootstrap", policy
  end

  def extend_bootstrap_policy policy
    extend_policy "bootstrap", policy
  end
  
  def load_policy id, policy
    possum.policy_load "cucumber/policy/#{id}", policy
  end

  def extend_policy id, policy
    possum.policy_extend "cucumber/policy/#{id}", policy
  end
  
  def make_full_id *tokens
    super tokens.join(":")
  end
  
  def possum
    login_as_role 'admin', admin_api_key unless @possum
    @possum
  end

  def admin_api_key
    @admin_api_key ||= Possum::Client.new(url: $possum_url).login $possum_account, 'admin', admin_password
  end
  
  def admin_password
    ENV['CONJUR_AUTHN_PASSWORD'] || 'admin'
  end

  def login_as_role login, api_key = nil
    unless api_key
      role = if login.index('/')
        login.split('/', 2).join(":")
      else
        [ "user", login ].join(":")
      end
      api_key = PossumClient.new('admin', admin_password).rotate_api_key role
    end
    @possum = PossumClient.new login, api_key
  end
end

World(PossumWorld)
