## List resources [/resources]

### List resources [GET /resources/{account}{?kind}{?search}{?limit}{?offset}{?count}]

Lists resources within an organization account.

If a `kind` query parameter is given, narrows results to only resources of that
kind.

If a `limit` is given, returns no more than that number of results. Providing an
`offset` skips a number of resources before returning the rest. In addition,
providing an `offset` will give `limit` a default value of 10 if none other is
provided. These two parameters can be combined to page through results.

If the parameter `count` is `true`, returns only the number of items in the
list.

#### Text search

If the `search` parameter is provided, narrows results to those pertaining to
the search query. Search works across resource IDs and the values of
annotations. It weights results so that those with matching `id` or a matching
value of an annotation called `name` appear first, then those with another
matching annotation value, and finally those with a matching `kind`.

#### Example with `curl` and `jq`

Suppose your organization name is "mycorp" and you want to search for the first
two resources matching the word "db":

```bash
curl -H "$(conjur authn authenticate -H)" \
     'https://eval.conjur.org/resources/mycorp?search=db&limit=2' \
     | jq .
```

<!-- include(partials/resource_kinds.md) -->

---

#### Request

<!-- include(partials/auth_header_table.md) -->

#### Response

| Code | Description                       |
|------|-----------------------------------|
|  200 | Resources returned as a JSON list |
|<!-- include(partials/http_401.md) -->|

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: variable (string, optional) - kind of object to list
  + search: password (string, optional) - search term used to narrow results
  + limit: 2 (number, optional) - maximum number of results to return
  + offset: 6 (number, optional) - number of results to skip
  + count: false (boolean, optional) - if true, return only the number of items in the list

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)

    ```
    [
      {
        "created_at": "2017-07-25T06:30:38.768+00:00",
        "id": "mycorp:variable:app-prod/db-password",
        "owner": "mycorp:policy:app-prod",
        "policy": "mycorp:policy:root",
        "permissions": [],
        "annotations": [],
        "secrets": [
          {
            "version": 1
          }
        ]
      },
      {
        "created_at": "2017-07-25T06:30:38.768+00:00",
        "id": "mycorp:policy:app-prod",
        "owner": "mycorp:user:admin",
        "policy": "mycorp:policy:root",
        "permissions": [],
        "annotations": [],
        "policy_versions": []
      }
    ]
    ```

