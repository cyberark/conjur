Feature: Display Variable fields.

  Background:
    When I run the code:
    """
    $conjur.resource('cucumber:variable:ssl-certificate')
    """

  Scenario: Display MIME type and kind
    Then the JSON at "mime_type" should be "application/x-pem-file"
    And the JSON at "kind" should be "SSL certificate"
