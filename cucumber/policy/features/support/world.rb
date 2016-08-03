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
  
  attr_reader :username, :password
  
  def initialize username, password
    @username = username
    @password = password
    @client = new_client
    @client.login $possum_account, username, password
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
  
  def public_keys id
    # This one uses raw RestClient::Resource because it doesn't require authentication
    require 'rest-client'
    id = make_full_id id
    RestClient::Resource.new($possum_url)["public_keys/#{id_path(id)}"].get
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
  
  def invoke &block
    @result = yield
    @result.tap do |result|
      puts result if @echo
    end
  end
  
  def load_policy policy
    require 'tempfile'
    file = Tempfile.new('policy')
    file.write policy
    file.flush
    system *(%w(possum policy load cucumber) + [ file.path ]) or raise "Failed to load policy: #{$?.exitstatus}"
  end
  
  def make_full_id *tokens
    super tokens.join(":")
  end
  
  def possum
    login_as_user 'admin' unless @possum
    @possum
  end

  # For users, the password is the username
  def login_as_user login
    @possum = PossumClient.new login, login
  end
end

World(PossumWorld)
