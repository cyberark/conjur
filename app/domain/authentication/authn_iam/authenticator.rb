require 'active_support'
require 'active_support/core_ext'
require 'net/ldap'
require 'json'
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

        is_trusted_by_aws? && (iam_role_matches? host_role)

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
    
      def iam_role_matches? resource
    
        return false if resource.nil?

        is_allowed_role = false
    
        split_assumed_role = @aws_response_hash["GetCallerIdentityResponse"]["GetCallerIdentityResult"]["Arn"].split(":")

        # removes the last 2 parts of login to be substituted by the info from getCallerIdentity
        host_prefix = (@login.split("/")[0..-3]).join("/")
        aws_account_id = split_assumed_role[4]
        aws_role_name = split_assumed_role[5].split("/")[1]

        host_to_match = "#{host_prefix}/#{aws_account_id}/#{aws_role_name}"

        Rails.logger.info("host to match = #{host_to_match}")

        @login.eql? host_to_match
        
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
