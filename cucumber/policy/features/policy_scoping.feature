@policy
Feature: Policies can be used to scope records by name and ownership.

  @acceptance
  Scenario: Declare a scoped policy
  
    This example shows how to use a scoped policy to represent who can access credentials for a Jenkins master. 
    The policy includes an SSH private key and API token; the `users` group can fetch them and the `admins` can update them.

    One or more `!policy` blocks can be declared in a policy file. Each policy creates a scoped set of roles 
    and resources. The policy is a role which owns everything defined in its body, and the IDs of all roles and resources 
    defined in the policy body are prefixed with the policy's `id`. For example, if a policy called 
    `jenkins/v1` defines a variable whose `id` is `private-key`, then:
    
    - The full name of the created variable will be `jenkins/v1/private-key`.
    - The owner of the variable will be be the role `<account>:policy:jenkins/v1`.
      
    Given I load a policy:
    """
    - !policy
      id: jenkins/v1
      annotations:
        description: Governs the Conjur layer which holds the Jenkins master
      body:
        - !group &users users
        - !group &admins admins
    
        - &variables
          - !variable private-key
          - !variable api-token
    
        - !permit
          role: *users
          privilege: [ read, execute ]
          resource: *variables
    
        - !permit
          role: *admins
          privilege: [ read, execute, update ]
          resource: *variables
    """
    When I list group resources
    Then the resource list includes group "jenkins/v1/users"
    And the resource list includes group "jenkins/v1/admins"
    When I list the roles permitted to execute variable "jenkins/v1/private-key"
    Then the role list includes policy "jenkins/v1"
    And the role list includes group "jenkins/v1/users"
