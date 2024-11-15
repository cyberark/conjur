# frozen_string_literal: true

require 'spec_helper'

# Raw Diff test cases
# These originate from the Policy Dry Run SD Simple and Complex Examples

rawdiff_rows_simple =
  {
    "annotations": [
      {
        "resource_id": "cucumber:user:barrett@example",
        "name": "user",
        "value": "barrett",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/secret01",
        "name": "variable",
        "value": "42",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permissions": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/secret01",
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/secret01",
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "resources": [
      {
        "resource_id": "cucumber:policy:example",
        "owner_id": "cucumber:user:admin",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:barrett@example",
        "owner_id": "cucumber:policy:example",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/secret01",
        "owner_id": "cucumber:policy:example",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "role_memberships": [
      {
        "role_id": "cucumber:policy:example",
        "member_id": "cucumber:user:admin",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:barrett@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "roles": [
      {
        "role_id": "cucumber:policy:example",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "credentials": [
      {
        "role_id": "cucumber:user:barrett@example",
        "client_id": nil,
        "restricted_to": [
          "127.0.0.1"
        ]
      }
    ]
  }

rawdiff_rows_simple =
  {
    "annotations": [
      {
        "resource_id": "cucumber:user:barrett@example",
        "name": "user",
        "value": "barrett",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/secret01",
        "name": "variable",
        "value": "42",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permissions": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/secret01",
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/secret01",
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "resources": [
      {
        "resource_id": "cucumber:policy:example",
        "owner_id": "cucumber:user:admin",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:barrett@example",
        "owner_id": "cucumber:policy:example",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/secret01",
        "owner_id": "cucumber:policy:example",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "role_memberships": [
      {
        "role_id": "cucumber:policy:example",
        "member_id": "cucumber:user:admin",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:barrett@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "roles": [
      {
        "role_id": "cucumber:policy:example",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "credentials": [
      {
        "role_id": "cucumber:user:barrett@example",
        "client_id": nil,
        "restricted_to": [
          "127.0.0.1"
        ]
      }
    ]
  }

rawdiff_rows_complex =
  {
    "annotations": [
      {
        "resource_id": "cucumber:group:example/alpha/secret-users",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:group:example/omega/secret-users",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:alice@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:annie@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:barrett@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:bob@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:carson@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/alpha/secret01",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/alpha/secret02",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/omega/secret01",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/omega/secret02",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permissions": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/alpha/secret01",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/alpha/secret01",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/alpha/secret02",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/alpha/secret02",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/omega/secret01",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/omega/secret01",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/omega/secret02",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/omega/secret02",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "resources": [
      {
        "resource_id": "cucumber:group:example/alpha/secret-users",
        "owner_id": "cucumber:policy:example/alpha",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:group:example/omega/secret-users",
        "owner_id": "cucumber:policy:example/omega",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:policy:example",
        "owner_id": "cucumber:user:admin",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:policy:example/alpha",
        "owner_id": "cucumber:user:alice@example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:policy:example/omega",
        "owner_id": "cucumber:user:bob@example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:alice@example",
        "owner_id": "cucumber:policy:example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:annie@example",
        "owner_id": "cucumber:policy:example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:barrett@example",
        "owner_id": "cucumber:policy:example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:bob@example",
        "owner_id": "cucumber:policy:example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:user:carson@example",
        "owner_id": "cucumber:policy:example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/alpha/secret01",
        "owner_id": "cucumber:policy:example/alpha",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/alpha/secret02",
        "owner_id": "cucumber:policy:example/alpha",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/omega/secret01",
        "owner_id": "cucumber:policy:example/omega",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "resource_id": "cucumber:variable:example/omega/secret02",
        "owner_id": "cucumber:policy:example/omega",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "role_memberships": [
      {
        "role_id": "cucumber:group:example/alpha/secret-users",
        "member_id": "cucumber:policy:example/alpha",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:group:example/alpha/secret-users",
        "member_id": "cucumber:user:annie@example",
        "admin_option": false,
        "ownership": false,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:group:example/omega/secret-users",
        "member_id": "cucumber:policy:example/omega",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:group:example/omega/secret-users",
        "member_id": "cucumber:user:barrett@example",
        "admin_option": false,
        "ownership": false,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:policy:example",
        "member_id": "cucumber:user:admin",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:policy:example/alpha",
        "member_id": "cucumber:user:alice@example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:policy:example/omega",
        "member_id": "cucumber:user:bob@example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:alice@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:annie@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:barrett@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:bob@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:carson@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "roles": [
      {
        "role_id": "cucumber:group:example/alpha/secret-users",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:group:example/omega/secret-users",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:policy:example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:policy:example/alpha",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:policy:example/omega",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:alice@example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:annie@example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:barrett@example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:bob@example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:carson@example",
        "created_at": "2024-09-19T21:12:45.102+00:00",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "credentials": [
      {
        "role_id": "cucumber:user:barrett@example",
        "client_id": nil,
        "restricted_to": [
          "127.0.0.1"
        ]
      }
    ]
  }

# Expected mapping results:
# borrowing test data from dto_spec.rb
#
mapped_roles_simple = [
  {
    "resource_id": "cucumber:policy:example",
    "owner_id": "cucumber:user:admin",
    "policy_id": "cucumber:policy:root",
    "memberships": [
      {
        "role_id": "cucumber:user:barrett@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:policy:example",
        "member_id": "cucumber:user:admin",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:user:barrett@example",
    "owner_id": "cucumber:policy:example",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:user:barrett@example",
        "name": "user",
        "value": "barrett",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permissions": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/secret01",
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/secret01",
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "credentials": [
      {
        "role_id": "cucumber:user:barrett@example",
        "client_id": nil,
        "restricted_to": [
          "127.0.0.1"
        ]
      }
    ],
    "members": [
      {
        "role_id": "cucumber:user:barrett@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  }
]

mapped_roles_complex = [
  {
    "resource_id": "cucumber:group:example/alpha/secret-users",
    "owner_id": "cucumber:policy:example/alpha",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:group:example/alpha/secret-users",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permissions": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/alpha/secret01",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/alpha/secret01",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/alpha/secret02",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/alpha/secret02",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:group:example/alpha/secret-users",
        "member_id": "cucumber:policy:example/alpha",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:group:example/alpha/secret-users",
        "member_id": "cucumber:user:annie@example",
        "admin_option": false,
        "ownership": false,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:group:example/omega/secret-users",
    "owner_id": "cucumber:policy:example/omega",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:group:example/omega/secret-users",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permissions": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/omega/secret01",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/omega/secret01",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/omega/secret02",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/omega/secret02",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:group:example/omega/secret-users",
        "member_id": "cucumber:policy:example/omega",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:group:example/omega/secret-users",
        "member_id": "cucumber:user:barrett@example",
        "admin_option": false,
        "ownership": false,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:policy:example",
    "owner_id": "cucumber:user:admin",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "memberships": [
      {
        "role_id": "cucumber:user:alice@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:annie@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:barrett@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:bob@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      },
      {
        "role_id": "cucumber:user:carson@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:policy:example",
        "member_id": "cucumber:user:admin",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:policy:example/alpha",
    "owner_id": "cucumber:user:alice@example",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "memberships": [
      {
        "role_id": "cucumber:group:example/alpha/secret-users",
        "member_id": "cucumber:policy:example/alpha",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:policy:example/alpha",
        "member_id": "cucumber:user:alice@example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:policy:example/omega",
    "owner_id": "cucumber:user:bob@example",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "memberships": [
      {
        "role_id": "cucumber:group:example/omega/secret-users",
        "member_id": "cucumber:policy:example/omega",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:policy:example/omega",
        "member_id": "cucumber:user:bob@example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:user:alice@example",
    "owner_id": "cucumber:policy:example",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:user:alice@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "memberships": [
      {
        "role_id": "cucumber:policy:example/alpha",
        "member_id": "cucumber:user:alice@example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:user:alice@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:user:annie@example",
    "owner_id": "cucumber:policy:example",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:user:annie@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "memberships": [
      {
        "role_id": "cucumber:group:example/alpha/secret-users",
        "member_id": "cucumber:user:annie@example",
        "admin_option": false,
        "ownership": false,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:user:annie@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:user:barrett@example",
    "owner_id": "cucumber:policy:example",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:user:barrett@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "credentials": [
      {
        "role_id": "cucumber:user:barrett@example",
        "client_id": nil,
        "restricted_to": [
          "127.0.0.1"
        ]
      }
    ],
    "memberships": [
      {
        "role_id": "cucumber:group:example/omega/secret-users",
        "member_id": "cucumber:user:barrett@example",
        "admin_option": false,
        "ownership": false,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:user:barrett@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:user:bob@example",
    "owner_id": "cucumber:policy:example",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:user:bob@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "memberships": [
      {
        "role_id": "cucumber:policy:example/omega",
        "member_id": "cucumber:user:bob@example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:user:bob@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:user:carson@example",
    "owner_id": "cucumber:policy:example",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:user:carson@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "members": [
      {
        "role_id": "cucumber:user:carson@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  }
]

mapped_resources_simple = [
  {
    "resource_id": "cucumber:variable:example/secret01",
    "owner_id": "cucumber:policy:example",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:variable:example/secret01",
        "name": "variable",
        "value": "42",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permitted": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/secret01",
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/secret01",
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      }
    ]
  }
]

mapped_resources_complex = [
  {
    "resource_id": "cucumber:variable:example/alpha/secret01",
    "owner_id": "cucumber:policy:example/alpha",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:variable:example/alpha/secret01",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permitted": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/alpha/secret01",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/alpha/secret01",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:variable:example/alpha/secret02",
    "owner_id": "cucumber:policy:example/alpha",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:variable:example/alpha/secret02",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permitted": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/alpha/secret02",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/alpha/secret02",
        "role_id": "cucumber:group:example/alpha/secret-users",
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:variable:example/omega/secret01",
    "owner_id": "cucumber:policy:example/omega",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:variable:example/omega/secret01",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permitted": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/omega/secret01",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/omega/secret01",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      }
    ]
  },
  {
    "resource_id": "cucumber:variable:example/omega/secret02",
    "owner_id": "cucumber:policy:example/omega",
    "created_at": "2024-09-19T21:12:45.102+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:variable:example/omega/secret02",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ],
    "permitted": [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/omega/secret02",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      },
      {
        "privilege": "read",
        "resource_id": "cucumber:variable:example/omega/secret02",
        "role_id": "cucumber:group:example/omega/secret-users",
        "policy_id": "cucumber:policy:root"
      }
    ]
  }
]

describe 'DataObjects::Mapper' do
  describe 'when using the Simple Examples from the SD' do
    let(:rawdiff_data) { rawdiff_rows_simple.to_h }

    context "then when mapping roles" do
      subject { DataObjects::Mapper.map_roles(rawdiff_data) }

      it 'should extract roles from given row elements' do
        expect(subject.values).to eq(mapped_roles_simple)
        expect(subject.length).to eq(2)
      end

      it 'should not mutate the input' do
        target_resource_id = "cucumber:user:barrett@example"
        found_object = rawdiff_data[:resources].find { |resource| resource[:resource_id] == target_resource_id }

        expect(subject.values).to eq(mapped_roles_simple)
        expect(subject[target_resource_id].object_id).to_not eq(found_object.object_id)
      end
    end

    context "then when mapping resources" do
      subject { DataObjects::Mapper.map_resources(rawdiff_data) }

      it 'should extract resources from given row elements' do
        expect(subject.values).to eq(mapped_resources_simple)
        expect(subject.length).to eq(1)
      end

      it 'should not mutate the input' do
        target_resource_id = "cucumber:variable:example/secret01"
        found_object = rawdiff_data[:resources].find { |resource| resource[:resource_id] == target_resource_id }

        expect(subject.values).to eq(mapped_resources_simple)
        expect(subject[target_resource_id].object_id).to_not eq(found_object.object_id)
      end
    end
  end

  describe 'when mapping the Complex Examples from the SD' do
    let(:rawdiff_data) { rawdiff_rows_complex.to_h }

    context "then when mapping roles" do
      subject { DataObjects::Mapper.map_roles(rawdiff_data) }

      it 'should extract roles from given row elements' do
        expect(subject.values).to eq(mapped_roles_complex)
        expect(subject.length).to eq(10)
      end
    end

    context "then when mapping resources" do
      subject { DataObjects::Mapper.map_resources(rawdiff_data) }

      it 'should extract resources from given row elements' do
        expect(subject.values).to eq(mapped_resources_complex)
        expect(subject.length).to eq(4)
      end
    end
  end
end
