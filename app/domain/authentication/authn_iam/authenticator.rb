require 'net/http'
require 'net/https'
require 'json'

module Authentication
  module AuthnIam
    class Authenticator
      
      def initialize(env:)
        @env = env
      end

      def valid?(input)
        @account, @login, password = input.account, input.username, input.password

        # JSON holding the AWS signed headers 
        signed_aws_headers = JSON.parse password

        response_hash = identity_response_hash(signed_aws_headers)
        trusted = response_hash != false

        (trusted) && (iam_role_matches? host_role, response_hash)

      end

      def identity_response_hash(signed_aws_headers)

        res = retrieve_iam_identity(signed_aws_headers)

        Rails.logger.info("****> #{res.code} #{res.message}")
        Rails.logger.info("**** Body -> #{res.body} ")

        if res.code.eql?("200")
          Hash.from_xml(res.body)
        else
          Rails.logger.error("****> #{res.code} #{res.message}")
          false
        end      

      end
    
      def iam_role_matches? resource, response_hash
    
        return false if resource.nil?

        is_allowed_role = false
    
        split_assumed_role = response_hash["GetCallerIdentityResponse"]["GetCallerIdentityResult"]["Arn"].split(":")

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

      def base_aws_request
        url = 'https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15'
      
        # Executes the AWS Signed Request
        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        https.set_debug_output($stdout)
        return https, Net::HTTP::Get.new(url)
      end

      def retrieve_iam_identity(aws_headers)

        Rails.logger.info("Retrieving IAM identity")
        
        https, aws_request = base_aws_request
        aws_headers.each do |key, value|
          aws_request.add_field(key, value)
        end
      
        Rails.logger.info("aws_request: #{aws_request}")

        https.request(aws_request)
      end

    end

  end
end
