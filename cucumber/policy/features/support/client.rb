
module ClientHelpers
  attr_reader :result

  class Client
    @@admin_password = 'SEcret12!!!!'
    @@account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
    @@appliance_url =  ENV['CONJUR_APPLIANCE_URL'] || 'http://conjur'

    def initialize(root_, kind_, id_)
      @id = id_ ||= 'blank'
      @kind = kind_
      @root = root_
    end

    def post_request(body, token=admin_token)
      client.post(body, header(token))
    end

    def fetch_request(token=admin_token)
      client.get(header(token))
    end

    def fetch_request_with_params(params, token=admin_token)
      client.get(header(token).merge(params))
    end

    def put_request(body, token=admin_token)
      client.put(body, header(token))
    end

    def patch_request(body, token=admin_token)
      client.patch(body, header(token))
    end

    def admin_token
        get_token('admin', admin_api_key)
    end

    def get_token login, key
      url = "#{@@appliance_url}/authn/#{@@account}/#{CGI.escape(login)}/authenticate"
      RestClient.post(url, key, 'Accept-Encoding': 'Base64')
    end

    def admin_api_key
      login_client('admin', @@admin_password).get()
    end

    def create_api_key role
      rotate_key_client.put(
        "", header(admin_token).merge(params: { role: role })
      )
    end

    def rotate_key_client
      url = "#{@@appliance_url}/authn/#{@@account}/api_key"
      RestClient::Resource.new(url, 'admin', @@admin_password)
    end

    def login_client user, password
      url = "#{@@appliance_url}/authn/#{@@account}/login"
      RestClient::Resource.new(url, user, password)
    end

    def client
      RestClient::Resource.new(uri, 'Content-Type' => 'application/json')
    end

    def header token
      token ||= admin_token
      { Authorization:  %Q(Token token="#{token}") }
    end

    def uri
      uri = "#{@@appliance_url}/#{@root}/#{@@account}/#{@kind}"
      return uri if @id == 'blank'

      "#{uri}/#{CGI.escape(@id)}"
    end

  end

  module Policyhelpers

    class PolicyClient
      @@kind = 'policy'
      @@root = 'policies'

      def initialize(id_)
        @id = id_ ||= 'blank'
      end

      def client
        Client.new(@@root, @@kind, @id)
      end

      def load_policy(policy)
        client.put_request(policy)
      end

      def update_policy(policy)
        client.patch_request(policy)
      end

      def extend_policy(policy)
        client.post_request(policy)
      end

    end

  end

  module ResourceHelper

    class ResourceClient

      def initialize(root_, kind_, id_)
        @id = id_ ||= 'blank'
        @kind = kind_
        @root = root_
      end

      def client
        Client.new(@root, @kind, @id)
      end

      def fetch_secret(token)
        client.fetch_request(token)
      end

      def fetch_resource(token=nil)
        client.fetch_request
      end

      def add_secret(value,token)
        client.post_request(value,token)
      end

      def fetch_privilaged_roles(privilege)
        client.fetch_request_with_params(privilege)
      end

    end

  end

end