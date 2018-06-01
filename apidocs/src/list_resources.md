## List resources [/resources]

### List resources [GET /resources/{account}{?kind}{?search}{?limit}{?offset}{?count}]

Lists resources within an organization account.

<!-- include(partials/search_kind.md) -->

<!-- include(partials/list_paging.md) -->

<!-- include(partials/list_count.md) -->

<!-- include(partials/search_text.md) -->

#### Example with `curl` and `jq`

Suppose your organization name is "myorg" and you want to search for the first
two resources matching the word "db":

```bash
curl -H "$(conjur authn authenticate -H)" \
     'https://eval.conjur.org/resources/myorg?search=db&limit=2' \
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
        "id": "myorg:variable:app-prod/db-password",
        "owner": "myorg:policy:app-prod",
        "policy": "myorg:policy:root",
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
        "id": "myorg:policy:app-prod",
        "owner": "myorg:user:admin",
        "policy": "myorg:policy:root",
        "permissions": [],
        "annotations": [],
        "policy_versions": []
      }
    ]
    ```

