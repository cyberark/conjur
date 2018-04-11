module Conjur
  class API
    module Router
      module V4
        extend Conjur::Escape::ClassMethods
        extend Conjur::QueryString
        extend self

        def authn_login account, username, password
          verify_account(account)
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)['users/login']
        end

        def authn_authenticate account, username
          verify_account(account)
          RestClient::Resource.new(Conjur.configuration.authn_url)['users'][fully_escape username]['authenticate']
        end

        # For v4, the authn-local message is the username.
        def authn_authenticate_local username, account, expiration, cidr, &block
          verify_account(account)
          
          raise "'expiration' is not supported for authn-local v4" if expiration
          raise "'cidr' is not supported for authn-local v4" if cidr

          username
        end

        def authn_rotate_api_key credentials, account, id
          verify_account(account)
          username = if id.kind == "user"
            id.identifier
          else
            [ id.kind, id.identifier ].join('/')
          end
          RestClient::Resource.new(Conjur.configuration.authn_url, credentials)['users']["api_key?id=#{username}"]
        end

        def authn_rotate_own_api_key account, username, password
          verify_account(account)
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)['users']["api_key"]
        end

        def host_factory_create_host token
          http_options = {
            headers: { authorization: %Q(Token token="#{token}") }
          }
          RestClient::Resource.new(Conjur.configuration.core_url, http_options)['host_factories']['hosts']
        end

        def host_factory_create_tokens credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['host_factories'][id.identifier]['tokens']
        end

        def host_factory_revoke_token credentials, token
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['host_factories']['tokens'][token]
        end

        def resources_resource credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['authz'][id.account]['resources'][id.kind][id.identifier]
        end

        def resources_check credentials, id, privilege, role
          options = {}
          options[:check] = true
          options[:privilege] = privilege
          if role
            options[:resource_id] = id
            roles_role(credentials, Id.new(role))[options_querystring options].get
          else
            resources_resource(credentials, id)[options_querystring options].get
          end
        end

        def resources_permitted_roles credentials, id, privilege
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['authz'][id.account]['roles']['allowed_to'][privilege][id.kind][id.identifier]
        end

        def roles_role credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['authz'][id.account]['roles'][id.kind][id.identifier]
        end

        def secrets_add credentials, id
          verify_account(id.account)
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['variables'][fully_escape id.identifier]['values']
        end

        def variable credentials, id
          verify_account(id.account)
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['variables'][fully_escape id.identifier]
        end

        def secrets_value credentials, id, options
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['variables'][fully_escape id.identifier]['value'][options_querystring options]
        end

        def secrets_values credentials, variable_ids
          options = {
            vars: Array(variable_ids).map { |v| fully_escape(v.identifier) }.join(',')
          }
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['variables']['values'][options_querystring options]
        end

        def group_attributes credentials, resource, id
          verify_account(id.account)
          JSON.parse(RestClient::Resource.new(Conjur.configuration.core_url, credentials)['groups'][fully_escape id.identifier].get)
        end

        def variable_attributes credentials, resource, id
          verify_account(id.account)
          JSON.parse(RestClient::Resource.new(Conjur.configuration.core_url, credentials)['variables'][fully_escape id.identifier].get)
        end

        def user_attributes credentials, resource, id
          verify_account(id.account)
          JSON.parse(RestClient::Resource.new(Conjur.configuration.core_url, credentials)['users'][fully_escape id.identifier].get)
        end

        def parse_group_gidnumber attributes
          attributes['gidnumber']
        end

        def parse_user_uidnumber attributes
          attributes['uidnumber']
        end

        def parse_variable_kind attributes
          attributes['kind']
        end

        def parse_variable_mime_type attributes
          attributes['mime_type']
        end

        def parse_members credentials, result
          result.collect do |json|
            RoleGrant.parse_from_json(json, credentials)
          end
        end

        protected

        def verify_account account
          raise "Expecting account to be #{Conjur.configuration.account.inspect}, got #{account.inspect}" unless Conjur.configuration.account == account
        end
      end
    end
  end
end
