# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnIam::Authenticator do
  def expired_aws_headers
    "{\"host\":\"sts.amazonaws.com\",\"x-amz-date\":\"20180620T025910Z\","\
    "\"x-amz-security-token\":\"FQoDYXdzEPv//////////wEaDHwvkDqh5pHmZNe5hSK3AzevmnHjzweG6m1in"\
    "/CQ8NB7PCY0nTtWsCXLU5FsHmOoXs6KgVOu8ucghebak4b/iaDCpSprH3GPjLcNatywkUEQqX8rQKy2DoKMy7ZMHNT1ivhEn "\
    "vE3HR0GPkkGGWYhLTTrQDdI5fBcb3yJ /TyrcmUuBTKXwQJmvcnDe505SPpuSZm7tdrDX5SpItMngqGcrRhCjuprpk5nPVwSQ"\
    "q6usp7hJYPmu/6u9eVP3rQ TFPldhRvRxu5rcssURdrIwbjMugZQff/8XERxyxPrTkJQekcqMvvV6gexDZcBOS1JtIsKfJEXU"\
    "mK3kwV4liQsUevxyanWMc4jT0tiBkDj2 nvXUFt6dejppdTTRdEtBXg5xZUrGDCQDUU9eBgydoTLGav9rWiM7bWtpP4A1m0E9"\
    "LoX47FScSDkqk0Hy6Dr9jzhb4HOodlgaldTs8BNlgN9xXgACdacdPqnhaYLCgAWsaUZPKuZmdyH96F59rcrVscf456ivXTrXp"\
    "t6pL1ZQyRCc04hkovErvv1L2CwEaGAc k0bvbq0pbzTftTh7 9xY3pFxbL AALoR0t2/CfhyomvoG72Cl/nvAo7  "\
    "m2QU\",\"x-amz-content-sha256\":\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b"\
    "855\",\"authorization\":\"AWS4-HMAC-SHA256 Credential=ASIAJJTVXJS5KDKXKNPQ/20180620/us-east-1/sts/aw"\
    "s4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token, Signature=230fa"\
    "38a232969747b77e82f6c845f63941ebde89eb2cc20ed1c6f2dbabc92b6\"}"
  end

  def valid_response 
    double('HTTPResponse', 
            code: 200, 
            body: %(
                <GetCallerIdentityResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
                    <GetCallerIdentityResult>
                        <Arn>arn:aws:sts::011915987442:assumed-role/MyApp/i-0a5702a5a078e1a00</Arn>
                        <UserId>AROAIYXQMEFIAVEOFMW5Y:i-0a5702a5a078e1a00</UserId>
                        <Account>011915987442</Account>
                    </GetCallerIdentityResult>
                    <ResponseMetadata>
                        <RequestId>f555066a-7417-11e8-8ded-8daed431985e</RequestId>
                    </ResponseMetadata>
                </GetCallerIdentityResponse> 
            )
    )
  end

  def invalid_response 
    double('HTTPResponse', 
            code: 404,
            body: "Error"
    )
  end

  def valid_login
    "host/myapp/011915987442/MyApp"
  end

  def invalid_login
    "host/myapp/InvalidAccount/InvalidRole"
  end

  let (:authenticator_instance) do
    Authentication::AuthnIam::Authenticator.new(env:[])
  end

  it "valid? with expired AWS headers" do
    subject = authenticator_instance
    parameters = double('AuthenticationParameters', credentials: expired_aws_headers)
    expect{subject.valid?(parameters)}.to(
        raise_error(Errors::Authentication::AuthnIam::InvalidAWSHeaders)
    )
  end

  it "validates identity_hash with valid response" do
    subject = authenticator_instance
    expect { subject.identity_hash(valid_response) }.to_not raise_error

    expect(subject.identity_hash(valid_response)).to have_key("GetCallerIdentityResponse")

    expected = {
        "GetCallerIdentityResponse" => a_hash_including(
                "GetCallerIdentityResult" => a_hash_including(
                    "Arn" => "arn:aws:sts::011915987442:assumed-role/MyApp/i-0a5702a5a078e1a00",
                    "UserId" => anything,
                    "Account" => anything
                )
        )
    }

    expect(subject.identity_hash(valid_response)).to include(expected)
    expect(subject.identity_hash(valid_response))
  end

  it "validates identity_hash with invalid response" do
    subject = authenticator_instance
    expect(subject.identity_hash(invalid_response)).to eq(false)
  end
  
  it "matches valid login to AWS IAM role (based on AWS response)" do
    subject = authenticator_instance
    identity_hash = subject.identity_hash(valid_response)

    expect(subject.iam_role_matches?(valid_login, identity_hash)).to eq(true)
    expect(subject.iam_role_matches?(invalid_login, identity_hash)).to eq(false)
  end

  it "fails invalid login with AWS IAM role (based on AWS response)" do
    subject = authenticator_instance
    identity_hash = subject.identity_hash(valid_response)

    expect(subject.iam_role_matches?(invalid_login, identity_hash)).to eq(false)
  end
end
