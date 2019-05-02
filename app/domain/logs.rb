# frozen_string_literal: true

require 'util/log_message_with_code_class'

unless defined? LogMessages::Authentication::OriginValidated
  # this wrapper is here so these classes will not be loaded by Rails
  # auto-load. #TODO: fix this in a proper manner

  module LogMessages

    module Authentication

      OriginValidated = ::Util::LogMessageWithCodeClass.new(
        msg: "Origin validated",
        code: "CONJ00003D"
      )

      module Security

        SecurityValidated = ::Util::LogMessageWithCodeClass.new(
          msg: "Security validated",
          code: "CONJ00001D"
        )

        UserNotAuthorized = ::Util::LogMessageWithCodeClass.new(
          msg: "User '{0}' is not authorized to authenticate with webservice '{1}'",
          code: "CONJ00002D"
        )

      end

      module AuthnOidc

        ExtractedUsernameFromIDToked = ::Util::LogMessageWithCodeClass.new(
          msg: "Extracted username '{0}' from ID Token",
          code: "CONJ00004D"
        )

        IDTokenDecodeSuccess = ::Util::LogMessageWithCodeClass.new(
          msg: "ID Token Decode succeeded",
          code: "CONJ00005D"
        )

        IDTokenVerificationSuccess = ::Util::LogMessageWithCodeClass.new(
          msg: "ID Token verification succeeded",
          code: "CONJ00006D"
        )

        OIDCProviderUri = ::Util::LogMessageWithCodeClass.new(
          msg: "Working with provider {0-provider-uri}",
          code: "CONJ00007D"
        )

        OIDCProviderDiscoverySuccess = ::Util::LogMessageWithCodeClass.new(
          msg: "Provider discovery succeeded",
          code: "CONJ00008D"
        )

        FetchProviderCertsSuccess = ::Util::LogMessageWithCodeClass.new(
          msg: "Fetched provider certificates successfully",
          code: "CONJ00009D"
        )

      end

      module AuthnK8s

        PodChannelOpen = ::Util::LogMessageWithCodeClass.new(
          msg: "Pod '{0-pod-name}' : channel open",
          code: "CONJ00010D"
        )

        PodChannelClosed = ::Util::LogMessageWithCodeClass.new(
          msg: "Pod '{0-pod-name}' : channel closed",
          code: "CONJ00011D"
        )

        PodChannelData = ::Util::LogMessageWithCodeClass.new(
          msg: "Pod '{0-pod-name}', channel '{1-cahnnel-name}': {2-message-data}",
          code: "CONJ00012D"
        )

        PodMessageData = ::Util::LogMessageWithCodeClass.new(
          msg: "Pod: '{0-pod-name}', message: '{1-message-type}', data: '{2-message-data}'",
          code: "CONJ00013D"
        )

        PodError = ::Util::LogMessageWithCodeClass.new(
          msg: "Pod '{0-pod-name}' error : '{1}'",
          code: "CONJ00014D"
        )

        CopySSLToPod = ::Util::LogMessageWithCodeClass.new(
          msg: "Copying SSL cert to {0-pod-namespace}/{1-pod-name}",
          code: "CONJ00015D"
        )

      end
    end
  end
end
