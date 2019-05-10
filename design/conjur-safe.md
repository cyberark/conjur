## Conjur Safe Resource

A Safe is a higher order resource. It includes a number of variables, groups, and permissions to simplify the process of working with collections of variables.


### Example
The following is an example policy creating a Safe resource:
```yml
# policies/databases/foo.yml
- !safe
  id: foo-database
  variables:
    - url
    - port
    - username
    - password
```
When a Safe resource is created, the following resource primitives are created:

**Variables:**
- `<safe-id>/url`
- `<safe-id>/port`
- `<safe-id>/username`
- `<safe-id>/password`

**Groups:**
- `<safe-id>/readers`: read/execute permission on above variables
- `<safe-id>/writers`: update permission on above variables
- `<safe-id>/admins`: read/execute/update permission on above variables

### Enabling access
As a Safe has three default groups associated with it, permissions are assigned slightly differently than a typical resource.

```yml
- !safe
  id: foo-database
  variables:
    - url
    - port
    - username
    - password

- !group database-users
- !group database-admins

- !grant
  member: !group database-users
  role: !group foo-database/readers

- !grant
  member: !group database-admins
  role: !group foo-database/admins
```

The above gives the `database-admins` group admin permission (ability to view, read, and update the four variables in the safe).  Similarly, the `database-users` group now has permission to retrieve all four variables in the `foo-database` Safe.

### Managing Safes

#### Update

**CLI**

**API**

#### Retrieve

**CLI**

**API**



# policies/databases/permissions.yml

# provide read access to connection
- !grant
  member: !layer staging/my-application
  role: !group staging/foo-database/connection-users

# (assumes the layer staging/my-application, exists)


# provide write access to connection
- !grant
  member: !group db-admins
  role: !group staging/foo-database/connection-admin

# (assumes the group db-admins, exists)```
```$ conjur policy load staging policies/databases/foo.yml
$ conjur policy load staging policies/databases/permissions.yml
$ echo '{"url": "https://blah.my-foo.myorg.com", "port": "5432", "username": "foo-user", "password": "password123"}' | conjur variable values add staging/foo-database -```
