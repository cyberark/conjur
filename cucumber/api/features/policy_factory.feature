Feature: Policy Factory

  Background:
    Given I am the super-user
    And I create a new user "alice"
    And I create a new user "bob"
    And I successfully PATCH "/policies/cucumber/policy/root" with body:
    """
    - !policy certificates
    - !policy-factory
      id: certificates
      base: !policy certificates
      template:
        - !variable
          id: <%=role.identifier%>
          annotations:
            provision/provisioner: context
            provision/context/parameter: value

        - !permit
          role: !user
            id: /<%=role.identifier%>
          resource: !variable
            id: <%=role.identifier%>
          privileges: [ read, execute ]

    - !policy nested-policy
    - !policy-factory
      id: nested-policy
      owner: !user alice
      base: !policy nested-policy
      template:
        - !host
          id: outer-<%=role.identifier%>
          owner: !user /<%=role.identifier%>
          annotations:
            outer: <%=role.identifier%>

        - !policy
          id: inner
          owner: !user /<%=role.identifier%>
          body:
            - !host
              id: inner-<%=role.identifier%>
              annotations:
                inner: <%=role.identifier%>

    - !policy edit-template
    - !policy-factory
      id: edit-template
      owner: !user alice
      base: !policy edit-template
      template:
        - !variable to-be-edited

    - !policy-factory
      id: root-factory
      template:
        - !variable created-in-root 

    - !policy annotated-variables
    - !policy-factory
      id: parameterized
      base: !policy annotated-variables
      template:
        - !variable
          id: <%=role.identifier%>
          annotations:
            description: <%=params[:description]%>

    - !permit
      role: !user bob
      resource: !policy-factory parameterized
      privileges: [ read ]

    - !permit
      role: !user alice
      resource: !policy-factory certificates
      privileges: [ read, execute ]

    - !permit
      role: !user alice
      resource: !policy-factory parameterized
      privileges: [ read, execute ]
    """
    
  Scenario: Dry run loading policy using a factory
    Given I login as "alice"

    When I POST "/policy_factories/cucumber/certificates?dry_run=true"
    Then the JSON should be:
    """
    {
      "policy_text": "---\n- !variable\n  id: alice\n  annotations:\n    provision/provisioner: context\n    provision/context/parameter: value\n- !permit\n  privilege:\n  - read\n  - execute\n  role: !user\n    id: \"/alice\"\n  resource: !variable\n    id: alice\n",
      "load_to": "certificates",
      "dry_run": true,
      "response": null
    }
    """
    
  Scenario: Nested policy within factory template
    Given I login as "alice"
    When I successfully POST "/policy_factories/cucumber/nested-policy"
    Then I successfully GET "/resources/cucumber/host/nested-policy/outer-alice"
    Then I successfully GET "/resources/cucumber/host/nested-policy/inner/inner-alice"

  Scenario: Load policy using a factory
    Given I login as "alice"
    And I set the "Content-Type" header to "multipart/form-data; boundary=demo"
    When I successfully POST "/policy_factories/cucumber/certificates" with body from file "policy-factory-context.txt"
    Then the JSON should be:
    """
    {
      "policy_text": "---\n- !variable\n  id: alice\n  annotations:\n    provision/provisioner: context\n    provision/context/parameter: value\n- !permit\n  privilege:\n  - read\n  - execute\n  role: !user\n    id: \"/alice\"\n  resource: !variable\n    id: alice\n",
      "load_to": "certificates",
      "dry_run": false,
      "response": {
        "created_roles": {
        },
        "version": 1
      }
    }
    """
    And I successfully GET "/secrets/cucumber/variable/certificates/alice"
    Then the JSON should be:
    """
    "test value"
    """

  Scenario: Load parameterized policy using a factory
    Given I login as "alice"

    When I POST "/policy_factories/cucumber/parameterized?description=first%20description"
    Then the JSON should be:
    """
    {
      "policy_text": "---\n- !variable\n  id: alice\n  annotations:\n    description: first description\n",
      "load_to": "annotated-variables",
      "dry_run": false,
      "response": {
        "created_roles": {
        },
        "version": 1
      }
    }
    """

  Scenario: Get a 404 response without read permission
    Given I login as "bob"
    When I POST "/policy_factories/cucumber/certificates"
    Then the HTTP response status code is 404

  Scenario: Get a 403 response without execute permission
    Given I login as "bob"
    When I POST "/policy_factories/cucumber/parameterized"
    Then the HTTP response status code is 403

  Scenario: A policy factory without a base loads into the root policy
    Given I POST "/policy_factories/cucumber/root-factory"
    And the HTTP response status code is 201
    Then I successfully GET "/resources/cucumber/variable/created-in-root"

  Scenario: I retrieve the policy factory template through the API
    Given I login as "alice"
    When I GET "/policy_factories/cucumber/edit-template/template"
    Then the HTTP response status code is 200
    And the JSON response should be:
    """
    {
      "body": "---\n- !variable\n  id: to-be-edited\n"
    }
    """

  Scenario: I update the policy factory template through the API
    Given I login as "alice"
    When I PUT "/policy_factories/cucumber/edit-template/template" with body:
    """
    ---\n- !variable replaced
    """
    Then the HTTP response status code is 202
    When I GET "/policy_factories/cucumber/edit-template/template"
    Then the JSON response should be:
    """
    {
      "body": "---\\n- !variable replaced"
    }
    """

  Scenario: I don't have permission to retrieve the policy factory template
    Given I login as "bob"
    When I GET "/policy_factories/cucumber/edit-template/template"
    Then the HTTP response status code is 404
