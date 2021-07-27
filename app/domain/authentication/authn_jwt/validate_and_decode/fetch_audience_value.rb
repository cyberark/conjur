require 'command_class'

module Authentication
  module AuthnJwt
    module ValidateAndDecode
      # Fetch and validate the audience from the JWT authenticator policy
      FetchAudienceValue = CommandClass.new(
        dependencies: {
          resource_class: ::Resource,
          fetch_required_secrets: ::Conjur::FetchRequiredSecrets.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do
        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingAudienceValue.new)
          
          return empty_audience_value unless audience_resource_exists?

          fetch_audience_secret_value
          validate_audience_secret_value

          @logger.info(LogMessages::Authentication::AuthnJwt::FetchedAudienceValue.new(audience_secret_value))

          audience_secret_value
        end

        private
        
        def audience_resource_exists?
          return @audience_resource_exists unless @audience_resource_exists.nil?

          @audience_resource_exists ||= !audience_resource.nil?
        end

        def audience_resource
          @audience_resource ||= @resource_class[audience_resource_id]
        end

        def audience_resource_id
          @audience_resource_id ||= "#{@authentication_parameters.authn_jwt_variable_id_prefix}/#{AUDIENCE_RESOURCE_NAME}"
        end
        
        def empty_audience_value
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingAudienceValue.new)
          String.new
        end
        
        def fetch_audience_secret_value
          audience_secret_value
        end

        def audience_secret_value
          @audience_secret_value ||= audience_required_secret[audience_resource_id]
        end
        
        def audience_required_secret
          @audience_required_secret ||= @fetch_required_secrets.call(resource_ids: [audience_resource_id])
        end

        def validate_audience_secret_value
          validate_audience_secret_has_value
          audience_secret_value_is_stringoruri
        end

        def validate_audience_secret_has_value
          raise Errors::Authentication::AuthnJwt::AudienceValueIsEmpty if audience_secret_value.blank?
        end

        # https://datatracker.ietf.org/doc/html/rfc7519#section-2 => StringOrURI
        # any value containing a ":" character MUST be a URI [RFC3986]
        def audience_secret_value_is_stringoruri
          URI::RFC3986_PARSER.parse(audience_secret_value) if audience_secret_value.include?(":")
        rescue => e
          raise Errors::Authentication::AuthnJwt::AudienceValueIsNotURI.new(e.inspect)
        end
      end
    end
  end
end
