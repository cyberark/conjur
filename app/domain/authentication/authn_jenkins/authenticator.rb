# frozen_string_literal: true
require 'json'

module Authentication
  module AuthnJenkins
    class Authenticator

      Err = Errors::Authentication::AuthnJenkins
      def initialize(env:)
        @env = env
      end

      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account:            @account,
          authenticator_name: @authenticator_name,
          service_id:         @service_id
        )
      end

      def http_get_request(url, username, password) 
        begin
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 5
          request = Net::HTTP::Get.new(uri.request_uri)
          request.basic_auth(username, password)
          http.request(request)
        rescue Net::OpenTimeout => e
          Rails.logger.error("Timeout to Jenkins host Exception #{e}. Jenkins host '#{url}' is most likely invalid. Validate this url can be accessed from the conjur server.")
          raise Err::HostNotFound, url
        end
      end

      def get_build_info(jenkins_url, job_path, build_number, username, password)
        jenkins_build_endpoint = "/job/#{job_path}/#{build_number}/api/json"
        jenkins_build_url = "#{jenkins_url}#{jenkins_build_endpoint}"
        http_get_request(jenkins_build_url, username, password)
      end

      def build_running?(response)
        body = response.body
        status_code = response.code

        Rails.logger.debug("Jenkins Build Response: #{body}")
        if status_code != '200'
          raise Err::BuildInfoError.new(jenkinsBuildURL, "#{status_code} - #{body}")
        end

        JSON.parse(body)['building']
      end

      def jenkins_public_key(response)
        public_key = response['X-Instance-Identity']

        public_key = "-----BEGIN PUBLIC KEY-----\n#{public_key}\n-----END PUBLIC KEY-----"
        Rails.logger.debug("Returned public key: #{public_key}")
        OpenSSL::PKey::RSA.new(public_key)
      end

      def parse_metadata(username, password)
        json_body = JSON.parse password

        build_number = json_body["buildNumber"]
        signature = Base64.decode64(json_body["signature"])
        job_property_host_prefix = json_body["jobProperty_hostPrefix"]
        if json_body.key?("jobProperty_hostPrefix")
          job_name = username.sub("host/#{job_property_host_prefix}/", "")
        else
          job_name = username.sub("host/", "")
        end
        job_path = job_name.split("/").join("/job/")

        return job_name, job_path, build_number, signature
      end

      def valid?(input)
        @account = input.account
        @service_id = input.service_id
        @authenticator_name = input.authenticator_name
        
        # Get needed secrets to connect into the jenkins API
        jenkins_username = webservice.variable("jenkinsUsername").secret.value
        jenkins_password = webservice.variable("jenkinsPassword").secret.value
        jenkins_url = webservice.variable("jenkinsURL").secret.value

        # Parse the body
        # e.g {"buildNumber": 5, "signature": "<base64 signature>", "jobProperty_hostPrefix": "myapp"}
        job_name, job_path, build_number, signature = parse_metadata(input.username, input.password)

        Rails.logger.debug("Job Name: #{job_name} | Build Number: #{build_number} | Signatature: #{signature}")

        # Validate job is running and signature was signed with the jenkins identities private key
        if build_running?(get_build_info(jenkins_url, job_path, build_number, jenkins_username, jenkins_password))
          jenkinsPublicKey = jenkins_public_key(http_get_request(jenkins_url, jenkins_username, jenkins_password))
          message = "#{job_name}-#{build_number}"

          if jenkinsPublicKey.verify(OpenSSL::Digest::SHA256.new, signature, message)
            return true
          else
            Rails.logger.error("AUTHENTICATION FAILED: Data tampered or private-public key mismatch.")
            raise Err::InvalidSignature
          end
        else
          Rails.logger.error("AUTHENTICATION FAILED: Job '#{job_name} ##{build_number}' is currently not running.")
          raise Err::RunningJobNotFound "#{job_name} ##{build_number}"
        end
      end
    end
  end
end
