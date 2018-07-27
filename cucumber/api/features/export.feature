Feature: Export Conjur Open Source data

   The database and data key from Conjur can be exported to import
   into a Conjur EE appliance

   Scenario: Export using `conjurctl`
   When I run conjurctl export
   Then the export file exists
