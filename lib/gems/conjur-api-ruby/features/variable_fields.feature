Feature: Display Variable fields.

  Background:
    Given I run the code:
    """
    $conjur.load_policy 'root', <<-POLICY
    - !variable
      id: ssl-certificate
      kind: SSL certificate
      mime_type: application/x-pem-file
    POLICY
    """
    And I run the code:
    """
    $conjur.resource('cucumber:variable:ssl-certificate')
    """

  Scenario: Display MIME type and kind
    Then the JSON at "mime_type" should be "application/x-pem-file"
    And the JSON at "kind" should be "SSL certificate"
