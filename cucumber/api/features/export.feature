@api
Feature: Export Conjur Open Source data

   The database and data key from Conjur can be exported to import
   into a Conjur EE appliance

   Background:
   Given I create a new user "admin" in account "export_account"

   @smoke
   Scenario: Export using `conjurctl`
   When I run conjurctl export
   Then the export file exists
   And the accounts file contains "export_account"

   @acceptance
   Scenario: Export with chosen label
   When I run conjurctl export with label "my_export"
   Then the export file exists with label "my_export"
