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

class Possum::API
  include FullId
  
  require 'cgi'
  require 'json'
  require 'rest-client'
  require 'base64'
  
  attr_reader :username, :password
  
  def initialize username, password
    @username = username
    @password = password
  end
  
  def credentials
    headers = {}.tap do |h|
      h[:authorization] = "Token token=\"#{Base64.strict_encode64 token.to_json}\""
    end
    { headers: headers, username: username }
  end

  def resource_show id
    id = make_full_id id
    JSON::parse(RestClient::Resource.new($possum_url, credentials)["resources/#{id_path(id)}"].get)
  end

  def resource_list options = {}
    params = options.inject([]) do |memo, entry|
      memo.push "#{CGI.escape entry[0].to_s}=#{CGI.escape entry[1].to_s}"
      memo
    end
    
    JSON::parse(RestClient::Resource.new($possum_url, credentials)["resources/#{$possum_account}?#{params.join('&')}"].get)
  end
  
  def resource_check id, privilege
    id = make_full_id id
    JSON::parse(RestClient::Resource.new($possum_url, credentials)["resources/#{id_path(id)}?check&privilege=#{privilege}"].get)
  end

  def resource_permitted_roles id, privilege
    id = make_full_id id
    JSON::parse(RestClient::Resource.new($possum_url, credentials)["resources/#{id_path(id)}?permitted_roles&privilege=#{privilege}"].get)
  end

  def role_show id
    id = make_full_id id
    JSON::parse(RestClient::Resource.new($possum_url, credentials)["roles/#{id_path(id)}"].get)
  end
  
  protected
  
  def id_path id
    id.gsub(':', '/')
  end
  
  def token
    JSON::parse(RestClient::Resource.new($possum_url)["authn/#{CGI.escape username}/authenticate"].post password, content_type: 'text/plain')
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
    system *(%w(possum policy load) + [ file.path ]) or raise "Failed to load policy: #{$?.exitstatus}"
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
    @possum = Possum::API.new login, login
  end
end

World(PossumWorld)
