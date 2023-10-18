# frozen_string_literal: true

module Authentication
  module AuthnAws
    module V2

      # Handles validation of the request body for an AWS IAM token
      class Strategy
        def initialize(authenticator:, logger: Rails.logger, client: Net::HTTP)
          @authenticator = authenticator
          @logger = logger
          @client = client
        end

        # This method is the primary access point for authentication.
        #
        # @param [String] request_body - POST body content
        # @param [Hash] parameters - GET parameters on the request
        #
        # @return [Authenticator::RoleIdentifier] - Information required to match a Conjur Role
        #
        # The parameter argument is required by the AuthenticationHandler,
        # but not used by this strategy.
        #
        # rubocop:disable Lint/UnusedMethodArgument
        #
        def callback(request_body:, parameters:)
          # TODO: Check that `id` is present in the parameters list

          signed_aws_headers = JSON.parse(request_body).transform_keys(&:downcase)
          aws_response = response_from_signed_request(signed_aws_headers)

          Authenticator::Base::RoleIdentifier.new(
            role_identifier: role_from_iam_role(
              host: params[:id],
              aws_arn: aws_response[:arn],
              aws_account: aws_response[:account]
            )
          )
        end

        # Called by status handler. This handles checking as much of the strategy
        # integrity as possible without performing an actual authentication.
        def verify_status
          true
        end

        private

        # Parses STS Caller Identity response for the Conjur host and resolves it against the provided login
        # def iam_role_matches?(login:, aws_arn:, aws_account:)
        def role_from_iam_role(host:, aws_arn:, aws_account:)
          # removes the last 2 parts of login to be substituted by the info from getCallerIdentity
          host_prefix = (host.split('/')[0..-3]).join('/')

          arn_parts = aws_arn.split(':')
          aws_role_name = arn_parts[5].split('/')[1]
          host_identifier = "#{host_prefix}/#{aws_account}/#{aws_role_name}"

          # @logger.debug(
          #   LogMessages::Authentication::AuthnIam::AttemptToMatchHost.new(
          #     host,
          #     host_identifier
          #   )
          # )

          "#{@authenticator.service_id}:host:#{host_identifier}"

          # login.eql?(host_to_match)
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

        # Call to AWS STS endpoint using the provided authentication header
        def attempt_signed_request(signed_headers)
          region = extract_sts_region(signed_headers)

          # Attempt request using the discovered region and return immediately if successful
          response = aws_call(region: region, headers: signed_headers)
          return response if response.code.to_i == 200

          # If the discovered region is `us-east-1`, fallback to the global endpoint
          if region == 'us-east-1'
            @logger.debug(LogMessages::Authentication::AuthnIam::RetryWithGlobalEndpoint.new)
            fallback_response = aws_call(region: 'global', headers: signed_headers)
            return fallback_response if fallback_response.code.to_i == 200
          end

          return response
        end

        def extract_relevant_data(response)
          {
            arn: response.dig('GetCallerIdentityResponse', 'GetCallerIdentityResult', 'Arn'),
            account: response.dig('GetCallerIdentityResponse', 'GetCallerIdentityResult', 'Account')
          }
        end

        # Extracts the STS region from the host header if it exists.
        # If not, we use the authorization header's credential string, i.e.:
        # Credential=AKIAIOSFODNN7EXAMPLE/20220830/us-east-1/sts/aws4_request
        def extract_sts_region(signed_headers)
          host = signed_headers['host']

          if host == 'sts.amazonaws.com'
            return 'global'
          end

          match = host&.match(%r{sts.([\w\-]+).amazonaws.com})
          return match.captures.first if match

          match = signed_headers['authorization']&.match(%r{Credential=[^/]+/[^/]+/([^/]+)/})
          return match.captures.first if match

          raise Errors::Authentication::AuthnIam::InvalidAWSHeaders, 'Failed to extract AWS region from authorization header'
        end

        def aws_call(region:, headers:)
          host = if region == 'global'
            'sts.amazonaws.com'
          else
            "sts.#{region}.amazonaws.com"
          end
          aws_request = URI("https://#{host}/?Action=GetCallerIdentity&Version=2011-06-15")
          begin
            @client.get_response(aws_request, headers)
          rescue => e
            # Handle any network failures with a generic verification error
            raise(Errors::Authentication::AuthnIam::VerificationError, e)
          end
        end

      end
    end
  end
end
