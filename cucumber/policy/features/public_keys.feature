@policy
Feature: Public keys can be associated with user records.

  @smoke
  Scenario: Public keys can be managed through policy.
    Conjur can store public keys for each of your users. To store a public key, use the
    `public_keys` attribute on the `!user` record. When you load a user policy containing
    public keys, any existing public keys that aren't in the new policy will be removed.
    
    Public keys that you load in policies should use the form:
    
    <algorithm> <public-key> <comment>
    
    The comment is required, so that multiple public keys can be distinguished from each other.

    Given I load a policy:
    """
    - !user
      id: alice
      public_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkP8DBDkCiPxnoXgSnrWq9QkYZ6mUmSsWQIEH81eSvllH+lTZQjgNwvwTaSSpBJ5QupyMf9/PCcP3D7weSrL3YkUSvb0GtE6Sq0mehHAPUNuT8qfXpjFVUe50LcGTUfqrD6EGdn+9t6PXeg7dFVyZt66Lg4ei3If7K+VeWDqaHFIIBevy/qLD8WEjKYBSfzf0cgxuRmfrqeu67bbL2ipHMhZQ0ZkVneQ5O++eRmbiEE3eoza6ut/jcPk5dzX+LHhJIZhI5JOyhRPxnrCrQkipoKtJgj3xxSCFfYQNvH9dAZZK6CTkY2SQT8YbAxgKagJ+JTg2LzKz3WzEe49HhIqxF laptop
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCxWrx+rPfp6YWGujtDwsY3tj8KmYsSD6nuog+2V6PgKYBAsrxOnUme2VNZ5LXxZ1KrkD4GmXxy01aEmpDFmwMWnszQFgoQI5pO2XEqtt7T63jA0htKzDqELEp/FZLQv5wQUILgQlnnPK6WrueIbhfP0o8SRBnEau6pt/rD44CAToObzLe7b7vPXDzP8SRj7iPsAfYsyr+UjOe7vIvgs5bLhKuWgPiXnbheurPgqsCcGwQ9VxVFxPsdGL5ANwQzmUlCddcTg370samqSSy9jzIKvai9yd+2KuFj3AviqhZN4fxKn8A0NTFX0wgi4U46HDTzt2NTERuWhcP36b+4ZLN workstation
    """
    Then there is a public_key resource "user/alice/laptop"
    And there is a public_key resource "user/alice/workstation"
    And  I list the public keys for "alice"
    Then the result is:
    """
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkP8DBDkCiPxnoXgSnrWq9QkYZ6mUmSsWQIEH81eSvllH+lTZQjgNwvwTaSSpBJ5QupyMf9/PCcP3D7weSrL3YkUSvb0GtE6Sq0mehHAPUNuT8qfXpjFVUe50LcGTUfqrD6EGdn+9t6PXeg7dFVyZt66Lg4ei3If7K+VeWDqaHFIIBevy/qLD8WEjKYBSfzf0cgxuRmfrqeu67bbL2ipHMhZQ0ZkVneQ5O++eRmbiEE3eoza6ut/jcPk5dzX+LHhJIZhI5JOyhRPxnrCrQkipoKtJgj3xxSCFfYQNvH9dAZZK6CTkY2SQT8YbAxgKagJ+JTg2LzKz3WzEe49HhIqxF laptop
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCxWrx+rPfp6YWGujtDwsY3tj8KmYsSD6nuog+2V6PgKYBAsrxOnUme2VNZ5LXxZ1KrkD4GmXxy01aEmpDFmwMWnszQFgoQI5pO2XEqtt7T63jA0htKzDqELEp/FZLQv5wQUILgQlnnPK6WrueIbhfP0o8SRBnEau6pt/rD44CAToObzLe7b7vPXDzP8SRj7iPsAfYsyr+UjOe7vIvgs5bLhKuWgPiXnbheurPgqsCcGwQ9VxVFxPsdGL5ANwQzmUlCddcTg370samqSSy9jzIKvai9yd+2KuFj3AviqhZN4fxKn8A0NTFX0wgi4U46HDTzt2NTERuWhcP36b+4ZLN workstation

    """

  @smoke
  Scenario: The latest public key version is the one provided by the pubkeys API.
    Public keys that you load in policies use the form:
    
    <algorithm> <public-key> <comment>
    
    In the case that a key is loaded multiple times with the same comment, the last public key loaded is the one returned by the pubkeys API.

    Given I load a policy:
    """
    - !user
      id: alice
      public_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkP8DBDkCiPxnoXgSnrWq9QkYZ6mUmSsWQIEH81eSvllH+lTZQjgNwvwTaSSpBJ5QupyMf9/PCcP3D7weSrL3YkUSvb0GtE6Sq0mehHAPUNuT8qfXpjFVUe50LcGTUfqrD6EGdn+9t6PXeg7dFVyZt66Lg4ei3If7K+VeWDqaHFIIBevy/qLD8WEjKYBSfzf0cgxuRmfrqeu67bbL2ipHMhZQ0ZkVneQ5O++eRmbiEE3eoza6ut/jcPk5dzX+LHhJIZhI5JOyhRPxnrCrQkipoKtJgj3xxSCFfYQNvH9dAZZK6CTkY2SQT8YbAxgKagJ+JTg2LzKz3WzEe49HhIqxF laptop
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCxWrx+rPfp6YWGujtDwsY3tj8KmYsSD6nuog+2V6PgKYBAsrxOnUme2VNZ5LXxZ1KrkD4GmXxy01aEmpDFmwMWnszQFgoQI5pO2XEqtt7T63jA0htKzDqELEp/FZLQv5wQUILgQlnnPK6WrueIbhfP0o8SRBnEau6pt/rD44CAToObzLe7b7vPXDzP8SRj7iPsAfYsyr+UjOe7vIvgs5bLhKuWgPiXnbheurPgqsCcGwQ9VxVFxPsdGL5ANwQzmUlCddcTg370samqSSy9jzIKvai9yd+2KuFj3AviqhZN4fxKn8A0NTFX0wgi4U46HDTzt2NTERuWhcP36b+4ZLN laptop
    """
    Then there is a public_key resource "user/alice/laptop"
    And  I list the public keys for "alice"
    Then the result should not contain:
    """
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkP8DBDkCiPxnoXgSnrWq9QkYZ6mUmSsWQIEH81eSvllH+lTZQjgNwvwTaSSpBJ5QupyMf9/PCcP3D7weSrL3YkUSvb0GtE6Sq0mehHAPUNuT8qfXpjFVUe50LcGTUfqrD6EGdn+9t6PXeg7dFVyZt66Lg4ei3If7K+VeWDqaHFIIBevy/qLD8WEjKYBSfzf0cgxuRmfrqeu67bbL2ipHMhZQ0ZkVneQ5O++eRmbiEE3eoza6ut/jcPk5dzX+LHhJIZhI5JOyhRPxnrCrQkipoKtJgj3xxSCFfYQNvH9dAZZK6CTkY2SQT8YbAxgKagJ+JTg2LzKz3WzEe49HhIqxF laptop
    """
