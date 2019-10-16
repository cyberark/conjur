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

      def httpGetRequest(url, username, password) 
        begin
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 5
          request = Net::HTTP::Get.new(uri.request_uri)
          request.basic_auth(username, password)
          response = http.request(request)
        rescue Net::OpenTimeout => e
          Rails.logger.error("Timeout to Jenkins host Exception #{e.to_s}")
          Rails.logger.error("Jenkins host '#{url}' is most likely invalid. Validate this url can be accessed from the conjur server.")
          raise Err::HostNotFound, url
        end

        return response
      end

      def buildRunning?(jenkinsURL, jobPath, buildNumber, username, password)
        jenkinsBuildEndpoint = "/job/#{jobPath}/#{buildNumber}/api/json"
        jenkinsBuildURL = "#{jenkinsURL}#{jenkinsBuildEndpoint}"
        response = httpGetRequest(jenkinsBuildURL, username, password)

        Rails.logger.debug("Jenkins Build Response: #{response.body}")

        if response.code != '200'
          raise Err::BuildInfoError.new(jenkinsBuildURL, "#{response.code} - #{response.body}")
        end

        json = JSON.parse(response.body)
        return json['building']
      end

      def getPublicKey(jenkinsURL, username, password)
        response = httpGetRequest(jenkinsURL, username, password)
        publicKey = response['X-Instance-Identity']

        publicKey = "-----BEGIN PUBLIC KEY-----\n#{publicKey}\n-----END PUBLIC KEY-----"
        Rails.logger.debug("Returned public key: #{publicKey}")
        return OpenSSL::PKey::RSA.new(publicKey)
      end

      def valid?(input)
        # Needed to create the webservice object
        @account = input.account
        @service_id = input.service_id
        @authenticator_name = input.authenticator_name

        # Get needed secrets to connect into the jenkins API
        jenkinsUsername = webservice.variable("jenkinsUsername").secret.value
        jenkinsPassword = webservice.variable("jenkinsPassword").secret.value
        jenkinsURL = webservice.variable("jenkinsURL").secret.value

        # Parse the body
        # e.g {"buildNumber": 5, "signature": "<base64 signature>", "jobProperty_hostPrefix": "myapp"}
        jsonBody = JSON.parse input.password
        buildNumber = jsonBody["buildNumber"]
        signature = Base64.decode64(jsonBody["signature"])
        jobProperty_hostPrefix = jsonBody["jobProperty_hostPrefix"]
        if jsonBody.key?("jobProperty_hostPrefix")
          jobName = input.username.sub("host/#{jobProperty_hostPrefix}/", "")
        else
          jobName = input.username.sub("host/", "")
        end
        jobPath = jobName.split("/").join("/job/")


        Rails.logger.debug("Jenkins job name: #{jobName}")
        Rails.logger.debug("Jenkins build number: #{buildNumber}")
        Rails.logger.debug("Jenkins signature: #{signature}")

        # Validate job is running and signature was signed with the jenkins identities private key
        if buildRunning?(jenkinsURL, jobPath, buildNumber, jenkinsUsername, jenkinsPassword)
          jenkinsPublicKey = getPublicKey(jenkinsURL, jenkinsUsername, jenkinsPassword)
          message = "#{jobName}-#{buildNumber}"

          if jenkinsPublicKey.verify(OpenSSL::Digest::SHA256.new, signature, message)
              return true
          else
            Rails.logger.error("AUTHENTICATION FAILED: Data tampered or private-public key mismatch.")
            raise Err::InvalidSignature
          end
        else
          Rails.logger.error("AUTHENTICATION FAILED: Job '#{jobName} ##{buildNumber}' is currently not running.")
          raise Err::RunningJobNotFound "#{jobName} ##{buildNumber}"
        end
        false
      end
    end
  end
end