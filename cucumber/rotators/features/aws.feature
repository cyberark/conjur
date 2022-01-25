# NOTE: Run this manual test in the cucumber container with the command:
#      
#           bundle exec cucumber -p manual-rotators
#         
#       Before you run it for the first time, you must set add your AWS test
#       account credentials to the following ENV variables:
#
#           export AWS_DEFAULT_REGION=us-east-1
#           export AWS_ACCESS_KEY_ID=<your id>
#           export AWS_SECRET_ACCESS_KEY=<your access key>
#
# NOTE: Please use the file `aws_show_credentials` to view the latest valid
#       credentials after you are done testing.
#
#       Before running it:
#
#           STOP THE CONJUR SERVER IN THE CONJUR CONTAINER
#
#       After running it:
#
#           RECORD THEM SOMEWHERE SAFE.  OTHERWISE YOU'LL BE LOCKED OUT.
#
# NOTE: We need the 11s ttl here (rather than the 1s we normally use in
#       tests) because new AWS credentials don't actually start working
#       instantly.
#
@manual
@rotators
Feature: AWS Secret Access Key Rotation

  Background: Configure an AWS rotator
    Given I reset my root policy
    And I have the root policy:
    """
    - !policy
      id: aws
      body:
        - !variable region
        - !variable access_key_id
        - !variable secret_key_proxy
        - !variable
          id: secret_access_key
          annotations:
            rotation/rotator: aws/secret-key
            rotation/ttl: PT11S
    """
    And I ensure conjur has AWS test account credentials for policy "aws"

  @smoke
  Scenario: Values are rotated according to the policy
    Given I moniter AWS variables in policy "aws" for 3 values in 50 seconds
    Then the last two sets of AWS credentials both work
    And the previous ones do not work
