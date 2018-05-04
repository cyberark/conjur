require 'types'
require 'active_support'
require 'active_support/core_ext'
require 'net/ldap'
require 'json'
require 'conjur-api'
require 'aws-sdk-iam'
require 'aws-sdk-core'


module Authentication
  module AuthnIam

    class Authenticator
      
      
      def initialize(env:)
        @env = env
      end

      def valid?(input)
        @authn_name, @account, @login, password, @service_id = input.authenticator_name, input.account, input.username, input.password, input.service_id

        # JSON holding the AWS signed headers 
        @signed_aws_headers = JSON.parse input.password

        is_trusted_by_aws? && (is_role_allowed_for_resource? host_role)

      end

      def is_trusted_by_aws?

        url = 'https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15'

        # Executes the AWS Signed Request
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        https.set_debug_output($stdout)
        request = Net::HTTP::Get.new(url)

        @signed_aws_headers.each do |key, value|
          request.add_field(key, value)
        end

        res = https.request(request)

        Rails.logger.info("request => #{request}")
        Rails.logger.info("****> #{res.code} #{res.message}")
        Rails.logger.info("**** Body -> #{res.body} ")

        @aws_response_hash = Hash.from_xml(res.body) if res.code.eql? "200"

        res.code.eql? "200"

      end
    
      def is_role_allowed_for_resource? resource
    
        return false if resource.nil?

        is_allowed_role = false
    
        resource_annotations = resource_annotations resource
        split_assumed_role = @aws_response_hash["GetCallerIdentityResponse"]["GetCallerIdentityResult"]["Arn"].split("/")
        caller_role_arn = (split_assumed_role.first split_assumed_role.size - 1).join("/") # ARN (to match) by removing the last item 

        JSON.parse(resource_annotations["iam_allowed_roles"]).include? caller_role_arn
        
      end      

      def host_role
        host_role ||= ::Resource[::Authentication::MemoizedRole.roleid_from_username(@account, @login)]
      end

      def service
        @service ||= ::Resource["#{@account}:webservice:conjur/#{@authn_name}/#{@service_id}"]
      end

      def resource_annotations resource
        Hash[resource.annotations.collect { |item| [item.name, item.value] } ]
      end
          
      def service_annotations
        @service_annotations ||= resource_annotations service
      end

    end

  end
end
