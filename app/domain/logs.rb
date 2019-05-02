# frozen_string_literal: true

require 'util/trackable_log_message_class'

unless defined? LogMessages::Authentication::OriginValidated
  # This wrapper prevents classes from being loaded by Rails
  # auto-load. #TODO: fix this in a proper manner

  module LogMessages

    module Authentication

      OriginValidated = ::Util::TrackableLogMessageClass.new(
        msg: "Origin validated",
        code: "CONJ00003D"
      )

      module Security

        SecurityValidated = ::Util::TrackableLogMessageClass.new(
          msg: "Security validated",
          code: "CONJ00001D"
        )

        UserNotAuthorized = ::Util::TrackableLogMessageClass.new(
          msg: "User '{0}' is not authorized to authenticate with webservice '{1}'",
          code: "CONJ00002D"
        )

      end

      module AuthnOidc

        ExtractedUsernameFromIDToked = ::Util::TrackableLogMessageClass.new(
          msg: "Extracted username '{0}' from ID Token",
          code: "CONJ00004D"
        )

        IDTokenDecodeSuccess = ::Util::TrackableLogMessageClass.new(
          msg: "ID Token decode succeeded",
          code: "CONJ00005D"
        )

        IDTokenVerificationSuccess = ::Util::TrackableLogMessageClass.new(
          msg: "ID Token verification succeeded",
          code: "CONJ00006D"
        )

        OIDCProviderUri = ::Util::TrackableLogMessageClass.new(
          msg: "Working with OIDC Provider {0-provider-uri}",
          code: "CONJ00007D"
        )

        OIDCProviderDiscoverySuccess = ::Util::TrackableLogMessageClass.new(
          msg: "OIDC Provider discovery succeeded",
          code: "CONJ00008D"
        )

        FetchProviderCertsSuccess = ::Util::TrackableLogMessageClass.new(
          msg: "Fetched OIDC Provider certificates successfully",
          code: "CONJ00009D"
        )

      end

      module AuthnK8s

        PodChannelOpen = ::Util::TrackableLogMessageClass.new(
          msg: "Pod '{0-pod-name}' : channel open",
          code: "CONJ00010D"
        )

        PodChannelClosed = ::Util::TrackableLogMessageClass.new(
          msg: "Pod '{0-pod-name}' : channel closed",
          code: "CONJ00011D"
        )

        PodChannelData = ::Util::TrackableLogMessageClass.new(
          msg: "Pod '{0-pod-name}', channel '{1-cahnnel-name}': {2-message-data}",
          code: "CONJ00012D"
        )

        PodMessageData = ::Util::TrackableLogMessageClass.new(
          msg: "Pod: '{0-pod-name}', message: '{1-message-type}', data: '{2-message-data}'",
          code: "CONJ00013D"
        )

        PodError = ::Util::TrackableLogMessageClass.new(
          msg: "Pod '{0-pod-name}' error : '{1}'",
          code: "CONJ00014D"
        )

        CopySSLToPod = ::Util::TrackableLogMessageClass.new(
          msg: "Copying SSL certificate to {0-pod-namespace}/{1-pod-name}",
          code: "CONJ00015D"
        )

      end
    end
  end
end
