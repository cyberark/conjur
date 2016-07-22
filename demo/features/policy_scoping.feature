Feature: Policies can be used to scope records by name and ownership.

  Scenario: Declare a scoped policy
  
    This example shows how to use a scoped policy to represent who can access credentials for a Jenkins master. 
    The policy includes an SSH private key and API token; the `users` group can fetch them and the `admins` can update them.

    One or more `!policy` blocks can be declared in a policy file. This effectively creates a scoped set of roles 
    and resources. The policy owns everything defined in its body. The IDs of all roles and resources 
    defined in the policy body are prefixed with the policy's `id`. 
    Policy blocks are therefore self-contained units. Loading the policy above with no namespace 
    would create these records:
    
    - Group `jenkins/v1/users`
    - Group `jenkins/v1/admins`
    - Variable `jenkins/v1/private-key`
    - Variable `jenkins/v1/api-token`
    
    To reference global records within a policy block, prepend a `/` to their `id`.
      
    Given a policy:
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
    When I list "group" resources
    Then the resource list includes group "jenkins/v1/users"
    And the resource list includes group "jenkins/v1/admins"
    When I list the roles permitted to execute variable "jenkins/v1/private-key"
    Then the role list includes group "jenkins/v1/users"
