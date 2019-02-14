# frozen_string_literal: true

require 'json'

module Authentication
  module AuthnIam
    class Authenticator

      InvalidAWSHeaders = ::Util::ErrorClass.new("'Invalid or Expired AWS Headers: {0}")

      def initialize(env:)
        @env = env
      end

      def valid?(input)
        signed_aws_headers = JSON.parse input.password # input.password is JSON holding the AWS signed headers

        response_hash = identity_hash(response_from_signed_request(signed_aws_headers))
        trusted = response_hash != false

        trusted && iam_role_matches?(input.username, response_hash)
      end

      def identity_hash(response)
        Rails.logger.debug("AWS IAM get_caller_identity body\n#{response.body} ")

        if response.code < 300
          Hash.from_xml(response.body)
        else
          Rails.logger.error("Verification of IAM identity failed with HTTP code: #{response.code}")
          false
        end
      end

      def iam_role_matches?(login, response_hash)
        split_assumed_role = response_hash["GetCallerIdentityResponse"]["GetCallerIdentityResult"]["Arn"].split(":")

        # removes the last 2 parts of login to be substituted by the info from getCallerIdentity
        host_prefix = (login.split("/")[0..-3]).join("/")
        aws_role_name = split_assumed_role[5].split("/")[1]
        aws_account_id = response_hash["GetCallerIdentityResponse"]["GetCallerIdentityResult"]["Account"]
        aws_user_id = response_hash["GetCallerIdentityResponse"]["GetCallerIdentityResult"]["UserId"]
        host_to_match = "#{host_prefix}/#{aws_account_id}/#{aws_role_name}"

        Rails.logger.debug("IAM Role authentication attempt by AWS user #{aws_user_id} with host to match = #{host_to_match}")

        login.eql? host_to_match
      end

      def aws_signed_url
        return 'https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15'      
      end

      def response_from_signed_request(aws_headers)
        Rails.logger.debug("Retrieving IAM identity")
        RestClient.log = Rails.logger
        begin
          RestClient.get(aws_signed_url, headers = aws_headers)
        rescue RestClient::ExceptionWithResponse => e
          Rails.logger.error("Verification of IAM identity Exception #{e.to_s}")
          raise InvalidAWSHeaders, e.to_s
        end
      end
    end
  end
end

