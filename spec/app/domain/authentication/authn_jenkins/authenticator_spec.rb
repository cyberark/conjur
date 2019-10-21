# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnIam::Authenticator do

  def valid_password
    '{"keyAlgorithm":"RSA","signature":"RES28Uu9cmFfh8gipU4Vg2OvkwNnvUF25DQC5a+qcjVqHtxlR5+yjxTBBraip+0VZ+1GraHabln9XowQ9mH17CNTee+1PhxrqBEbFs+M19VYgb04qKeAYWnJXcCWm8DSP/EAScW5JcmKRb/eBWN3P9a4f7qv/3UDe2gLYeImhRCLRqnsfHRa2x9ptNfEogX3hy24KhKCWFBjDfTDIdrTnqiE+Dn37clXPJGmSELTvrQVL/cgXVJkmcTW+0L/fGgZOp00mjqyO7M7Xl2FKc2RrRYgTTS1WWMtAJ0em2j4IDyNvsJLOviCPRRUOs/5HPf/+Bfk3EJ+9ypyx5VUdjZQmg==","jobProperty_hostPrefix":"myapp/jenkins","buildNumber":"15"}'
  end

  def invalid_password
    '{"keyAlgorithm":"RSA","signature":"RES28Uu9cmFfh8gipU4Vg2OvkwNnvUF25DQC5a+qcjVqHtxlR5+yjxTBBraip+0VZ+1GraHabln9XowQ9mH17CNTee+1PhxrqBEbFs+M19VYgb04qKeAYWnJXcCWm8DSP/EAScW5JcmKRb/eBWN3P9a4f7qv/3UDe2gLYeImhRCLRqnsfHRa2x9ptNfEogX3hy24KhKCWFBjDfTDIdrTnqiE+Dn37clXPJGmSELTvrQVL/cgXVJkmcTW+0L/fGgZOp00mjqyO7M7Xl2FKc2RrRYgTTS1WWMtAJ0em2j4IDyNvsJLOviCPRRUOs/5HPf/+Bfk3EJ+9ypyx5VUdjZQmg==","jobProperty_hostPrefix":"myapp/jenkins"}'
  end

  def valid_build_response 
    double('HTTPResponse', 
            code: 200, 
            body: '{"_class":"org.jenkinsci.plugins.workflow.job.WorkflowRun","actions":[{"_class":"hudson.model.CauseAction","causes":[{"_class":"hudson.model.Cause$UserIdCause","shortDescription":"Started by user Admin","userId":"admin","userName":"Admin"}]},{},{},{},{},{},{"_class":"org.jenkinsci.plugins.pipeline.modeldefinition.actions.RestartDeclarativePipelineAction"},{},{},{},{"_class":"org.jenkinsci.plugins.workflow.job.views.FlowGraphAction"},{},{},{}],"artifacts":[],"building":true,"description":null,"displayName":"#15","duration":0,"estimatedDuration":372,"executor":{"_class":"hudson.model.OneOffExecutor"},"fullDisplayName":"testJob #15","id":"15","keepLog":false,"number":15,"queueId":104,"result":null,"timestamp":1571239175624,"url":"http://10.32.64.101:8080/job/testJob/15/","changeSets":[],"culprits":[],"nextBuild":null,"previousBuild":{"number":14,"url":"http://10.32.64.101:8080/job/testJob/14/"}}'
    )
  end

  def invalid_build_response_build_false
    double('HTTPResponse', 
            code: 200,
            body: '{"_class":"org.jenkinsci.plugins.workflow.job.WorkflowRun","actions":[{"_class":"hudson.model.CauseAction","causes":[{"_class":"hudson.model.Cause$UserIdCause","shortDescription":"Started by user Admin","userId":"admin","userName":"Admin"}]},{},{},{},{},{},{"_class":"org.jenkinsci.plugins.pipeline.modeldefinition.actions.RestartDeclarativePipelineAction"},{},{},{},{"_class":"org.jenkinsci.plugins.workflow.job.views.FlowGraphAction"},{},{},{}],"artifacts":[],"building":false,"description":null,"displayName":"#15","duration":0,"estimatedDuration":372,"executor":{"_class":"hudson.model.OneOffExecutor"},"fullDisplayName":"testJob #15","id":"15","keepLog":false,"number":15,"queueId":104,"result":null,"timestamp":1571239175624,"url":"http://10.32.64.101:8080/job/testJob/15/","changeSets":[],"culprits":[],"nextBuild":null,"previousBuild":{"number":14,"url":"http://10.32.64.101:8080/job/testJob/14/"}}'
    )
  end

  def invalid_build_response_not_200
    double('HTTPResponse', 
            code: 400,
            body: ''
    )
  end

  def invalid_public_key
    double('HTTPResponse', 
            code: 200,
            body: '',
            headers: {'X-Instance-Identity' => 'notreal'}
    )
  end

  def invalid_public_key_not_available
    double('HTTPResponse', 
            code: 200,
            body: ''
    )
  end

  def valid_public_key
    double('HTTPResponse', 
            code: 200,
            body: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhU/Sg1ubdTES9qVSj45US8SRKh3PCvXwezMzJ8Xp7Rhi0qpPQmSKireaJ+R7+yUkY9xsZ7eTxFw2gCJz5fQyWoryjwJaA9ZsDU6jFZIv+SYHvTf3LTZ+TWeYi6A/gxF6JMckawgviQ1MV9VuBan5D8B/P4GR7TbmqiZIvBWfjSayz3Yj+85/PraBJJNC8lTYK61XjDd981nGNddcJ1KG1ZUarsBKXEX45cNEQJ21ZpisELVpXySk4czOSA52bADsaLJDX5MKNjbQgG+jd9tWo+8w3J7rKPThLRroMGukqMT7l535YnwQ0IocbvrM5uX3okydwcEADNYr8QCW1BhxUwIDAQAB'
    )
  end

  let (:authenticator_instance) do
    Authentication::AuthnJenkins::Authenticator.new(env:[])
  end

  # Test build info endpoint
  it "validate build is running" do
    subject = authenticator_instance
    expect { subject.build_running?(valid_build_response) }.to_not raise_error

    expect { subject.build_running?(valid_build_response) }.to eq(true)
  end

  it "validate build is not running" do
    subject = authenticator_instance
    expect { subject.build_running?(invalid_build_response_build_false) }.to_not raise_error

    expect { subject.build_running?(invalid_build_response_build_false) }.to eq(false)
  end

  it "failed to get build info" do
    subject = authenticator_instance
    expect { subject.build_running?(invalid_build_response_not_200) }.to raise_error
  end


  # Test getting the public key from jenkins
  it "fail invalid public key" do
    subject = authenticator_instance
    expect { subject.jenkins_public_key?(invalid_public_key) }.to raise_error
  end

  it "fail non existant public key" do
    subject = authenticator_instance
    expect { subject.jenkins_public_key?(invalid_public_key_not_available) }.to raise_error
  end

  it "gets public key" do
    subject = authenticator_instance
    public_key_content = "-----BEGIN PUBLIC KEY-----\n#{valid_public_key['X-Instance-Identity']}\n-----END PUBLIC KEY-----"
    expect { subject.jenkins_public_key?(valid_public_key) }.to include(public_key_content)
  end


  # Test getting password
  it "parses invalid password" do
    subject = authenticator_instance
    subject.parse_password(invalid_password).to raise_error
  end

  it "parses valid password" do
    subject = authenticator_instance
    subject.parse_password(valid_password).to_not raise_error
  end

end