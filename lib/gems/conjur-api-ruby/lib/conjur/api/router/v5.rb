module Conjur
  class API
    module Router
      module V5
        extend Conjur::Escape::ClassMethods
        extend Conjur::QueryString
        extend Conjur::Cast
        extend self

        def authn_login account, username, password
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)[fully_escape account]['login']
        end

        def authn_authenticate account, username
          RestClient::Resource.new(Conjur.configuration.authn_url)[fully_escape account][fully_escape username]['authenticate']
        end

        # For v5, the authn-local message is a JSON string with account, sub, and optional fields.
        # Optional fields include the service_id and authn_type for a custom authenticator.
        def authn_authenticate_local username, account, expiration, cidr, service_id, authn_type, &block
          { account: account, sub: username }.tap do |params|
            params[:exp] = expiration if expiration
            params[:cidr] = cidr if cidr
            params[:service_id] = service_id if service_id
            params[:authn_type] = authn_type if authn_type
          end.to_json
        end

        def authn_update_password account, username, password
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)[fully_escape account]['password']
        end

        def authn_rotate_api_key credentials, account, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['authn'][path_escape account]["api_key?role=#{id}"]
        end

        def authn_rotate_own_api_key account, username, password
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)[fully_escape account]['api_key']
        end

        def host_factory_create_host token
          http_options = {
            headers: { authorization: %Q(Token token="#{token}") }
          }
          RestClient::Resource.new(Conjur.configuration.core_url, http_options)["host_factories"]["hosts"]
        end

        def host_factory_create_tokens credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['host_factory_tokens']
        end

        def host_factory_revoke_token credentials, token
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['host_factory_tokens'][token]
        end

        def policies_load_policy credentials, account, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['policies'][path_escape account]['policy'][path_escape id]
        end

        def public_keys_for_user account, username
          RestClient::Resource.new(Conjur.configuration.core_url)['public_keys'][fully_escape account]['user'][path_escape username]
        end

        def resources credentials, account, kind, options
          credentials ||= {}

          path = "/resources/#{path_escape account}" 
          path += "/#{path_escape kind}" if kind

          RestClient::Resource.new(Conjur.configuration.core_url, credentials)[path][options_querystring options]
        end

        def resources_resource credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['resources'][id.to_url_path]
        end

        def resources_permitted_roles credentials, id, privilege
          options = {}
          options[:permitted_roles] = true
          options[:privilege] = privilege
          resources_resource(credentials, id)[options_querystring options]
        end

        def resources_check credentials, id, privilege, role
          options = {}
          options[:check] = true
          options[:privilege] = privilege
          options[:role] = cast_to_id(role) if role
          resources_resource(credentials, id)[options_querystring options].get
        end

        def roles_role credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['roles'][id.to_url_path]
        end

        def secrets_add credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['secrets'][id.to_url_path]
        end

        def secrets_value credentials, id, options
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['secrets'][id.to_url_path][options_querystring options]
        end

        def secrets_values credentials, variable_ids
          options = {
            variable_ids: Array(variable_ids).join(',')
          }
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['secrets'][options_querystring(options).gsub("%2C", ',')]
        end

        def group_attributes credentials, resource, id
          resource_annotations resource
        end

        def variable_attributes credentials, resource, id
          resource_annotations resource
        end

        def user_attributes credentials, resource, id
          resource_annotations resource
        end

        def parse_group_gidnumber attributes
          HasAttributes.annotation_value attributes, 'conjur/gidnumber'
        end

        def parse_user_uidnumber attributes
          HasAttributes.annotation_value attributes, 'conjur/uidnumber'
        end

        def parse_variable_kind attributes
          HasAttributes.annotation_value attributes, 'conjur/kind'
        end

        def parse_variable_mime_type attributes
          HasAttributes.annotation_value attributes, 'conjur/mime_type'
        end

        def parse_members credentials, result
          result['members'].collect do |json|
            RoleGrant.parse_from_json(json, credentials)
          end
        end

        private

        def resource_annotations resource
          resource.attributes['annotations'] || {}
        end
      end
    end
  end
end
