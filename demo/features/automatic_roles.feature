Feature: Automatic roles can be used to automatically grant and revoke privileges.

  Scenario: Grant SSH access to hosts in a layer (with and without sudo)

    This example shows how to grant access to hosts in a layer, without having to directly
    grant the privileges on the hosts.
    
    The group `developers` is granted the `use_host` automatic role on layer `prod/bastion`, which will
    give the group `execute` privilege on the hosts in the layer. This privilege is automatically
    add to hosts as they join the layer, and revoked as they leave. 

    The group `operations` has `admin_host` privilege on the layer`s hosts. The `admin_host` 
    automatic role manages `update` privilege. 

    Note that we did not simply grant `execute` privilege on the layer itself.
    That operation would only manage access to the layer itself; we want to manage access to the hosts 
    IN the layer. To do that, we grant the layer's automatic roles.

    Given a policy:
    """
    - !group &dev developers
    
    - !group &ops operations
    
    - !layer &bastion prod/bastion
    
    - !host bastion-01
    
    - !grant
      role: !automatic-role
        record: *bastion
        role_name: use_host
      members: *dev
    
    - !grant
      role: !automatic-role
        record: *bastion
        role_name: admin_host
      members: *ops
      
    - !grant
      role: *bastion
      member: !host bastion-01
    """
    When I list the roles permitted to execute host "bastion-01"
    Then the role list includes group "developers"
    And the role list includes group "operations"
