# frozen_string_literal: true

require 'json'

module Authentication
  module AuthnIam
    class Authenticator

      def initialize(env:, logger: Rails.logger, client: Net::HTTP)
        @env = env
        @logger = logger
        @client = client
      end

      def valid?(input)
        # input.credentials is JSON holding the AWS signed headers
        signed_aws_headers = JSON.parse(input.credentials).transform_keys(&:downcase)
        aws_response = response_from_signed_request(signed_aws_headers)

        iam_role_matches?(
          login: input.username,
          aws_arn: aws_response[:arn],
          aws_account: aws_response[:account]
        )
      end

      private

      # Parses STS Caller Identity response for the Conjur host and resolves it against the provided login
      def iam_role_matches?(login:, aws_arn:, aws_account:)
        # removes the last 2 parts of login to be substituted by the info from getCallerIdentity
        host_prefix = (login.split('/')[0..-3]).join('/')

        arn_parts = aws_arn.split(':')
        aws_role_name = arn_parts[5].split('/')[1]
        host_to_match = "#{host_prefix}/#{aws_account}/#{aws_role_name}"

        @logger.debug(
          LogMessages::Authentication::AuthnIam::AttemptToMatchHost.new(
            login,
            host_to_match
          )
        )

        login.eql?(host_to_match)
      end

      def extract_relevant_data(response)
        {
          arn: response.dig('GetCallerIdentityResponse', 'GetCallerIdentityResult', 'Arn'),
          account: response.dig('GetCallerIdentityResponse', 'GetCallerIdentityResult', 'Account')
        }
      end

      # Call to AWS STS endpoint using the provided authentication header
      def attempt_signed_request(signed_headers)
        aws_request = URI("https://#{signed_headers['host']}/?Action=GetCallerIdentity&Version=2011-06-15")
        begin
          @client.get_response(aws_request, signed_headers)

          # Handle any network failures with a generic verification error
        rescue StandardError => e
          raise(Errors::Authentication::AuthnIam::VerificationError.new(e))
        end
      end

      # Verify request with STS and handle response (happy or sad paths)
      def response_from_signed_request(aws_headers)
        response = attempt_signed_request(aws_headers)
        body =  Hash.from_xml(response.body)

        return extract_relevant_data(body) if response.code.to_i == 200

        raise(
          Errors::Authentication::AuthnIam::InvalidAWSHeaders,
          body.dig('ErrorResponse', 'Error', 'Message').to_s.strip
        )
      end
    end
  end
end
