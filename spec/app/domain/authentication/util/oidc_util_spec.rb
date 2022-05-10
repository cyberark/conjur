require 'spec_helper'
require 'openid-connect'

RSpec.describe('Authentication::Util::OidcUtil') do
  describe('decode_token') do
    context "good token" do
      it "behaves" do
        token = 'jwt=eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCJ9.'\
              'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.'\
              'hZnl5amPk_I3tb4O-Otci_5XZdVWhPlFyVRvcqSwnDo_srcysDvhhKOD01DigPK1lJvTSTolyUgKGtpLqMfRDXQlekRsF4XhA'\
              'jYZTmcynf-C-6wO5EI4wYewLNKFGGJzHAknMgotJFjDi_NCVSjHsW3a10nTao1lB82FRS305T226Q0VqNVJVWhE4G0JQvi2TssRtCxYTqzXVt22iDKkXe'\
              'ZJARZ1paXHGV5Kd1CljcZtkNZYIGcwnj65gvuCwohbkIxAnhZMJXCLaVvHqv9l-AAUV7esZvkQR1IpwBAiDQJh4qxPjFGylyXrHMqh5NlT_pWL2ZoULWT'\
              'g_TJjMO9TuQ'

        config = class_double("::OpenIDConnect::Discovery::Provider::Config")
        discovery_response = double("::OpenIDConnect::Discovery::Provider::Config::Response")
        allow(config).to receive(:discover!).and_return(discovery_response)
        allow(discovery_response).to receive(:jwks).and_return(nil)
        oidc_util = Authentication::Util::OidcUtil.new(
          authenticator: Authenticator::OidcAuthenticator.new(
            account: "rspec",
            service_id: "abc123",
            required_payload_parameters: [:code, :state],
            name: "test",
            provider_uri: "http://test.com",
            response_type: "code",
            client_id: "client-id-192",
            client_secret: "nf3i2h0f2w0hfei20f",
            claim_mapping: "username",
            state: "statei0o3n",
            nonce: "noneo0j3409jhas",
            redirect_uri: "https://conjur.com"
          ),
          provider_discovery_config: config
        )

        token = oidc_util.decode_token(token)
        binding.pry
      end
    end

    context "testing" do
      it "works" do
        token = "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJtaXhWaTItVlkyV3BiZXJhSzQ0MDcxUkRzQmpMdThSZXBGMV9Lb1RFYTBBIn0.eyJqdGkiOiJiNGM3NDI1My01MzFkLTQ0ZjgtODk2ZS03ZWFiOTRmZjQ5YjQiLCJleHAiOjE2NTE2Nzk0ODQsIm5iZiI6MCwiaWF0IjoxNjUxNjc5NDI0LCJpc3MiOiJodHRwOi8va2V5Y2xvYWs6ODA4MC9hdXRoL3JlYWxtcy9tYXN0ZXIiLCJhdWQiOiJjb25qdXJDbGllbnQiLCJzdWIiOiJmNWRlZmFkMy1kNGNjLTRjNjMtOGEwMy04NDJjZjQ4OTExNTgiLCJ0eXAiOiJJRCIsImF6cCI6ImNvbmp1ckNsaWVudCIsImF1dGhfdGltZSI6MCwic2Vzc2lvbl9zdGF0ZSI6ImUxMDlhNzE1LThhNjgtNGZmMi04YzUwLWM0NDkyMmU5YmNkMiIsImFjciI6IjEiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsInByZWZlcnJlZF91c2VybmFtZSI6ImFsaWNlIiwiZW1haWwiOiJhbGljZUBjb25qdXIubmV0In0.WVcZ6L0mvvVs3DLmXXch0lH-9fB6k58XL23uR7RU_5PISRhoe6qjqPLbUYuEUQFwVbnmEgbeFndGIDpi0phJcdsghtRUM2N20NoGdBSNYR6SqTx85OvtEwzG33YSfN3U8_0pNNseKLMoSlwK9g14z9XOwFHVPv4laFIgqRNREhhkAuYCy0KEJ8APbkAe6lTA3cn7SXArKHCj_7ToZCFTOq6gNFpO8hntJ1H4XtA6w7wgP5WDC_5YXEyc37vJhmtIU5FL_OL5iaG_FwFlaMR3uiEKsel-uuKCaNEk2CArwpcbI69Wyf-5AmKkRnII_eiuOlrOcHyyUinWjoWqeqgEmg"


      end
    end
  end
end
