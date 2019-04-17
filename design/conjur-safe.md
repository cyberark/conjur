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
