# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::SigningKey::CreateJwksFromHttpResponse') do

  let(:mocked_http_response_unsuccessful) { double("MockedHttpResponse") }
  let(:http_error) { "400 Bad Request" }
  let(:http_url) { "https://jwks/address" }
  let(:mocked_http_response_with_invalid_json_structure) { double("MockedHttpResponse") }
  let(:mocked_http_response_without_keys) { double("MockedHttpResponse") }
  let(:mocked_http_response_with_empty_keys) { double("MockedHttpResponse") }
  let(:mocked_http_response_with_valid_keys) { double("MockedHttpResponse") }
  let(:http_body_invalid_json_structure) { "{  invalid:  {  structure: true  }" }
  let(:http_body_without_keys) { '{"no_keys":[{"kty":"RSA","kid":"kewiQq9jiC84CvSsJYOB-N6A8WFLSV20Mb-y7IlWDSQ","e":"AQAB","n":"5RyvCSgBoOGNE03CMcJ9Bzo1JDvsU8XgddvRuJtdJAIq5zJ8fiUEGCnMfAZI4of36YXBuBalIycqkgxrRkSOENRUCWN45bf8xsQCcQ8zZxozu0St4w5S-aC7N7UTTarPZTp4BZH8ttUm-VnK4aEdMx9L3Izo0hxaJ135undTuA6gQpK-0nVsm6tRVq4akDe3OhC-7b2h6z7GWJX1SD4sAD3iaq4LZa8y1mvBBz6AIM9co8R-vU1_CduxKQc3KxCnqKALbEKXm0mTGsXha9aNv3pLNRNs_J-cCjBpb1EXAe_7qOURTiIHdv8_sdjcFTJ0OTeLWywuSf7mD0Wpx2LKcD6ImENbyq5IBuR1e2ghnh5Y9H33cuQ0FRni8ikq5W3xP3HSMfwlayhIAJN_WnmbhENRU-m2_hDPiD9JYF2CrQneLkE3kcazSdtarPbg9ZDiydHbKWCV-X7HxxIKEr9N7P1V5HKatF4ZUrG60e3eBnRyccPwmT66i9NYyrcy1_ZNN8D1DY8xh9kflUDy4dSYu4R7AEWxNJWQQov525v0MjD5FNAS03rpk4SuW3Mt7IP73m-_BpmIhW3LZsnmfd8xHRjf0M9veyJD0--ETGmh8t3_CXh3I3R9IbcSEntUl_2lCvc_6B-m8W-t2nZr4wvOq9-iaTQXAn1Au6EaOYWvDRE","use":"sig","alg":"RS256"},{"kty":"RSA","kid":"4i3sFE7sxqNPOT7FdvcGA1ZVGGI_r-tsDXnEuYT4ZqE","e":"AQAB","n":"4cxDjTcJRJFID6UCgepPV45T1XDz_cLXSPgMur00WXB4jJrR9bfnZDx6dWqwps2dCw-lD3Fccj2oItwdRQ99In61l48MgiJaITf5JK2c63halNYiNo22_cyBG__nCkDZTZwEfGdfPRXSOWMg1E0pgGc1PoqwOdHZrQVqTcP3vWJt8bDQSOuoZBHSwVzDSjHPY6LmJMEO42H27t3ZkcYtS5crU8j2Yf-UH5U6rrSEyMdrCpc9IXe9WCmWjz5yOQa0r3U7M5OPEKD1-8wuP6_dPw0DyNO_Ei7UerVtsx5XSTd-Z5ujeB3PFVeAdtGxJ23oRNCq2MCOZBa58EGeRDLR7Q","use":"sig","alg":"RS256"}]}' }
  let(:http_body_with_empty_keys) { '{"keys":[]}' }
  let(:http_body_with_valid_keys) { '{"keys":[{"kty":"RSA","kid":"kewiQq9jiC84CvSsJYOB-N6A8WFLSV20Mb-y7IlWDSQ","e":"AQAB","n":"5RyvCSgBoOGNE03CMcJ9Bzo1JDvsU8XgddvRuJtdJAIq5zJ8fiUEGCnMfAZI4of36YXBuBalIycqkgxrRkSOENRUCWN45bf8xsQCcQ8zZxozu0St4w5S-aC7N7UTTarPZTp4BZH8ttUm-VnK4aEdMx9L3Izo0hxaJ135undTuA6gQpK-0nVsm6tRVq4akDe3OhC-7b2h6z7GWJX1SD4sAD3iaq4LZa8y1mvBBz6AIM9co8R-vU1_CduxKQc3KxCnqKALbEKXm0mTGsXha9aNv3pLNRNs_J-cCjBpb1EXAe_7qOURTiIHdv8_sdjcFTJ0OTeLWywuSf7mD0Wpx2LKcD6ImENbyq5IBuR1e2ghnh5Y9H33cuQ0FRni8ikq5W3xP3HSMfwlayhIAJN_WnmbhENRU-m2_hDPiD9JYF2CrQneLkE3kcazSdtarPbg9ZDiydHbKWCV-X7HxxIKEr9N7P1V5HKatF4ZUrG60e3eBnRyccPwmT66i9NYyrcy1_ZNN8D1DY8xh9kflUDy4dSYu4R7AEWxNJWQQov525v0MjD5FNAS03rpk4SuW3Mt7IP73m-_BpmIhW3LZsnmfd8xHRjf0M9veyJD0--ETGmh8t3_CXh3I3R9IbcSEntUl_2lCvc_6B-m8W-t2nZr4wvOq9-iaTQXAn1Au6EaOYWvDRE","use":"sig","alg":"RS256"},{"kty":"RSA","kid":"4i3sFE7sxqNPOT7FdvcGA1ZVGGI_r-tsDXnEuYT4ZqE","e":"AQAB","n":"4cxDjTcJRJFID6UCgepPV45T1XDz_cLXSPgMur00WXB4jJrR9bfnZDx6dWqwps2dCw-lD3Fccj2oItwdRQ99In61l48MgiJaITf5JK2c63halNYiNo22_cyBG__nCkDZTZwEfGdfPRXSOWMg1E0pgGc1PoqwOdHZrQVqTcP3vWJt8bDQSOuoZBHSwVzDSjHPY6LmJMEO42H27t3ZkcYtS5crU8j2Yf-UH5U6rrSEyMdrCpc9IXe9WCmWjz5yOQa0r3U7M5OPEKD1-8wuP6_dPw0DyNO_Ei7UerVtsx5XSTd-Z5ujeB3PFVeAdtGxJ23oRNCq2MCOZBa58EGeRDLR7Q","use":"sig","alg":"RS256"}]}' }
  let(:valid_jwks) { {:keys => JSON::JWK::Set.new(JSON.parse(http_body_with_valid_keys)['keys'])} }

  before(:each) do
    allow(mocked_http_response_unsuccessful).to(
      receive(:value).and_raise(http_error)
    )

    allow(mocked_http_response_unsuccessful).to(
      receive(:uri).and_return(http_url)
    )

    allow(mocked_http_response_with_invalid_json_structure).to(
      receive(:value)
    )

    allow(mocked_http_response_with_invalid_json_structure).to(
      receive(:body).and_return(http_body_invalid_json_structure)
    )

    allow(mocked_http_response_without_keys).to(
      receive(:value)
    )

    allow(mocked_http_response_without_keys).to(
      receive(:body).and_return(http_body_without_keys)
    )

    allow(mocked_http_response_with_empty_keys).to(
      receive(:value)
    )

    allow(mocked_http_response_with_empty_keys).to(
      receive(:body).and_return(http_body_with_empty_keys)
    )

    allow(mocked_http_response_with_valid_keys).to(
      receive(:value)
    )

    allow(mocked_http_response_with_valid_keys).to(
      receive(:body).and_return(http_body_with_valid_keys)
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "'http_response' input" do
    context "with unsuccessful http response" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::CreateJwksFromHttpResponse.new.call(
          http_response: mocked_http_response_unsuccessful
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(
                                Errors::Authentication::AuthnJwt::FailedToFetchJwksData,
                                /.*'#{http_url}' with error: #<RuntimeError: #{http_error}.*/)
      end
    end

    context "with invalid json structure" do
      subject do
        ::Authentication::AuthnJwt::SigningKey::CreateJwksFromHttpResponse.new.call(
          http_response: mocked_http_response_with_invalid_json_structure
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FailedToConvertResponseToJwks)
      end
    end

    context "with valid json structure" do
      context "when 'keys' are missing" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::CreateJwksFromHttpResponse.new.call(
            http_response: mocked_http_response_without_keys
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FetchJwksUriKeysNotFound)
        end
      end

      context "with empty 'keys' value" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::CreateJwksFromHttpResponse.new.call(
            http_response: mocked_http_response_with_empty_keys
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::FetchJwksUriKeysNotFound)
        end
      end

      context "with valid 'keys' value" do
        subject do
          ::Authentication::AuthnJwt::SigningKey::CreateJwksFromHttpResponse.new.call(
            http_response: mocked_http_response_with_valid_keys
          )
        end

        it "returns jwks value" do
          expect(subject).to eql(valid_jwks)
        end
      end
    end
  end
end
