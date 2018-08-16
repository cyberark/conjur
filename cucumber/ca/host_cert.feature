Feature: Conjur signs a CSR

Background: 
  Given a root CA
  And an intermediate CA

Scenario: Generate a host certificate
  When I generate a host CSR
  And I sign it using the intermediate CA
  Then the host certificate is valid according to the root CA
