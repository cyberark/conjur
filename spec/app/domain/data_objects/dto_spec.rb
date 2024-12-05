# frozen_string_literal: true

require 'spec_helper'

mapped_roles_simple = [
  {
    "resource_id": "cucumber:policy:example",
    "owner_id": "cucumber:user:admin",
    "created_at": "2024-09-19T21:27:33.052+00:00",
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
    "created_at": "2024-09-19T21:27:33.052+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:user:barrett@example",
        "name": "key",
        "value": "value",
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
mapped_resources_simple = [
  {
    "resource_id": "cucumber:variable:example/secret01",
    "owner_id": "cucumber:policy:example",
    "created_at": "2024-09-19T21:27:33.052+00:00",
    "policy_id": "cucumber:policy:root",
    "annotations": [
      {
        "resource_id": "cucumber:variable:example/secret01",
        "name": "key",
        "value": "value",
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
roles_dto_complex = [
  {
    "identifier": "cucumber:group:example/alpha/secret-users",
    "id": "example/alpha/secret-users",
    "type": "group",
    "owner": "cucumber:policy:example/alpha",
    "policy": "cucumber:policy:root",
    "permissions": {
      "execute": [
        "cucumber:variable:example/alpha/secret01",
        "cucumber:variable:example/alpha/secret02"
      ],
      "read": [
        "cucumber:variable:example/alpha/secret01",
        "cucumber:variable:example/alpha/secret02"
      ]
    },
    "annotations": {
      "key": "value"
    },
    "members": [
      "cucumber:policy:example/alpha",
      "cucumber:user:annie@example"
    ],
    "memberships": [],
    "restricted_to": []
  },
  {
    "identifier": "cucumber:group:example/omega/secret-users",
    "id": "example/omega/secret-users",
    "type": "group",
    "owner": "cucumber:policy:example/omega",
    "policy": "cucumber:policy:root",
    "permissions": {
      "execute": [
        "cucumber:variable:example/omega/secret01",
        "cucumber:variable:example/omega/secret02"
      ],
      "read": [
        "cucumber:variable:example/omega/secret01",
        "cucumber:variable:example/omega/secret02"
      ]
    },
    "annotations": {
      "key": "value"
    },
    "members": [
      "cucumber:policy:example/omega",
      "cucumber:user:barrett@example"
    ],
    "memberships": [],
    "restricted_to": []
  },
  {
    "identifier": "cucumber:policy:example",
    "id": "example",
    "type": "policy",
    "owner": "cucumber:user:admin",
    "policy": "cucumber:policy:root",
    "permissions": {},
    "annotations": {},
    "members": [
      "cucumber:user:admin"
    ],
    "memberships": [
      "cucumber:user:alice@example",
      "cucumber:user:annie@example",
      "cucumber:user:barrett@example",
      "cucumber:user:bob@example",
      "cucumber:user:carson@example"
    ],
    "restricted_to": []
  },
  {
    "identifier": "cucumber:policy:example/alpha",
    "id": "example/alpha",
    "type": "policy",
    "owner": "cucumber:user:alice@example",
    "policy": "cucumber:policy:root",
    "permissions": {},
    "annotations": {},
    "members": [
      "cucumber:user:alice@example"
    ],
    "memberships": [
      "cucumber:group:example/alpha/secret-users"
    ],
    "restricted_to": []
  },
  {
    "identifier": "cucumber:policy:example/omega",
    "id": "example/omega",
    "type": "policy",
    "owner": "cucumber:user:bob@example",
    "policy": "cucumber:policy:root",
    "permissions": {},
    "annotations": {},
    "members": [
      "cucumber:user:bob@example"
    ],
    "memberships": [
      "cucumber:group:example/omega/secret-users"
    ],
    "restricted_to": []
  },
  {
    "identifier": "cucumber:user:alice@example",
    "id": "alice@example",
    "type": "user",
    "owner": "cucumber:policy:example",
    "policy": "cucumber:policy:root",
    "permissions": {},
    "annotations": {
      "key": "value"
    },
    "members": [
      "cucumber:policy:example"
    ],
    "memberships": [
      "cucumber:policy:example/alpha"
    ],
    "restricted_to": []
  },
  {
    "identifier": "cucumber:user:annie@example",
    "id": "annie@example",
    "type": "user",
    "owner": "cucumber:policy:example",
    "policy": "cucumber:policy:root",
    "permissions": {},
    "annotations": {
      "key": "value"
    },
    "members": [
      "cucumber:policy:example"
    ],
    "memberships": [
      "cucumber:group:example/alpha/secret-users"
    ],
    "restricted_to": []
  },
  {
    "identifier": "cucumber:user:barrett@example",
    "id": "barrett@example",
    "type": "user",
    "owner": "cucumber:policy:example",
    "policy": "cucumber:policy:root",
    "permissions": {},
    "annotations": {
      "key": "value"
    },
    "members": [
      "cucumber:policy:example"
    ],
    "memberships": [
      "cucumber:group:example/omega/secret-users"
    ],
    "restricted_to": [
      "127.0.0.1"
    ]
  },
  {
    "identifier": "cucumber:user:bob@example",
    "id": "bob@example",
    "type": "user",
    "owner": "cucumber:policy:example",
    "policy": "cucumber:policy:root",
    "permissions": {},
    "annotations": {
      "key": "value"
    },
    "members": [
      "cucumber:policy:example"
    ],
    "memberships": [
      "cucumber:policy:example/omega"
    ],
    "restricted_to": []
  },
  {
    "identifier": "cucumber:user:carson@example",
    "id": "carson@example",
    "type": "user",
    "owner": "cucumber:policy:example",
    "policy": "cucumber:policy:root",
    "permissions": {},
    "annotations": {
      "key": "value"
    },
    "members": [
      "cucumber:policy:example"
    ],
    "memberships": [],
    "restricted_to": []
  }
]
resources_dto_complex = [
  {
    "identifier": "cucumber:variable:example/alpha/secret01",
    "id": "example/alpha/secret01",
    "type": "variable",
    "owner": "cucumber:policy:example/alpha",
    "policy": "cucumber:policy:root",
    "permitted": {
      "execute": [
        "cucumber:group:example/alpha/secret-users"
      ],
      "read": [
        "cucumber:group:example/alpha/secret-users"
      ]
    },
    "annotations": {
      "key": "value"
    }
  },
  {
    "identifier": "cucumber:variable:example/alpha/secret02",
    "id": "example/alpha/secret02",
    "type": "variable",
    "owner": "cucumber:policy:example/alpha",
    "policy": "cucumber:policy:root",
    "permitted": {
      "execute": [
        "cucumber:group:example/alpha/secret-users"
      ],
      "read": [
        "cucumber:group:example/alpha/secret-users"
      ]
    },
    "annotations": {
      "key": "value"
    }
  },
  {
    "identifier": "cucumber:variable:example/omega/secret01",
    "id": "example/omega/secret01",
    "type": "variable",
    "owner": "cucumber:policy:example/omega",
    "policy": "cucumber:policy:root",
    "permitted": {
      "execute": [
        "cucumber:group:example/omega/secret-users"
      ],
      "read": [
        "cucumber:group:example/omega/secret-users"
      ]
    },
    "annotations": {
      "key": "value"
    }
  },
  {
    "identifier": "cucumber:variable:example/omega/secret02",
    "id": "example/omega/secret02",
    "type": "variable",
    "owner": "cucumber:policy:example/omega",
    "policy": "cucumber:policy:root",
    "permitted": {
      "execute": [
        "cucumber:group:example/omega/secret-users"
      ],
      "read": [
        "cucumber:group:example/omega/secret-users"
      ]
    },
    "annotations": {
      "key": "value"
    }
  }
]

describe 'DataObjects::PrimitiveFactory' do
  context 'when is_sensitive is false' do
    let(:subject) { DataObjects::PrimitiveFactory.new(is_sensitive: false) }

    context "when passed a database row as a hash" do
      let(:dto1a) { subject.from_hash(hash: mapped_roles_simple[0]) }
      let(:dto1b) { subject.from_hash(hash: mapped_roles_simple[1]) }
      let(:dto2a) { subject.from_hash(hash: mapped_resources_simple[0]) }
      it 'should return a RoleDTO or a ResourceDTO' do
        expect(dto1a.class).to be(DataObjects::Role)
        expect(dto1b.class).to be(DataObjects::Role)
        expect(dto2a.class).to be(DataObjects::Resource)
      end
      it 'should have the correct attributes for identifier, id, type, owner and policy' do
        expect(dto1a.identifier).to eq("cucumber:policy:example")
        expect(dto1a.type).to eq("policy")
        expect(dto1a.id).to eq("example")
        expect(dto1a.owner).to eq("cucumber:user:admin")
        expect(dto1a.policy).to eq("cucumber:policy:root")
        expect(dto2a.identifier).to eq("cucumber:variable:example/secret01")
        expect(dto2a.type).to eq("variable")
        expect(dto2a.id).to eq("example/secret01")
        expect(dto2a.owner).to eq("cucumber:policy:example")
        expect(dto2a.policy).to eq("cucumber:policy:root")
        expect(dto1b.identifier).to eq("cucumber:user:barrett@example")
        expect(dto1b.type).to eq("user")
        expect(dto1b.id).to eq("barrett@example")
        expect(dto1b.owner).to eq("cucumber:policy:example")
        expect(dto1b.policy).to eq("cucumber:policy:root")
      end

      it 'should build the correct arrays for members, memberships, and restricted_to' do
        expect(dto1a.members).to eq(["cucumber:user:admin"])
        expect(dto1a.memberships).to eq(["cucumber:user:barrett@example"])
        expect(dto1a.restricted_to).to eq([])
        expect(dto1b.members).to eq(["cucumber:policy:example"])
        expect(dto1b.memberships).to eq([])
        expect(dto1b.restricted_to).to eq(["127.0.0.1"])
      end

      it 'should build the correct hashes for permissions/permitted and annotations' do
        expect(dto1a.permissions).to eq(Hash(nil))
        expect(dto1a.annotations).to eq(Hash(nil))
        expect(dto1b.permissions).to match(a_hash_including("execute" => ["cucumber:variable:example/secret01"],
                                                            "read" => ["cucumber:variable:example/secret01"]))
        expect(dto1b.annotations).to match(a_hash_including("key" => "value"))
      end
    end

    context 'when passed a database row as a hash without necessary info' do
      bad_data_1 = { "resource_id": "cucumber:policy:example", "owner_id": nil, "created_at": nil, "policy_id": nil }
      bad_data_2 = { "resource_id": nil, "owner_id": nil, "created_at": nil, "policy_id": nil }
      it 'should raise an error for nil content in required fields' do
        expect { subject.from_hash(hash: bad_data_1) }.to raise_error(ArgumentError)
        expect { subject.from_hash(hash: bad_data_2) }.to raise_error(ArgumentError)
      end
      bad_data_3 = { "resource_id": "cucumber:policy:example" }
      it 'should raise an error for missing required fields ' do
        expect { subject.from_hash(hash: bad_data_3) }.to raise_error(ArgumentError)
      end
    end

    context 'when passed several role entries as an array of hashes' do
      let(:dtos) { subject.from_hashes(hashes: mapped_roles_complex) }
      it 'should return an array of RoleDTO structs' do
        expect(dtos.class).to be(Array)
        dtos.each do |dto|
          expect(dto.class).to be(DataObjects::Role)
        end
      end
      it 'should build identically when called in an array or individually ' do
        dtos.each_with_index do |dto, idx|
          expect(dto).to eq(subject.from_hash(hash: mapped_roles_complex[idx]))
        end
      end
      it 'should return an array of RoleDTO structs with the correct attributes' do
        dtos.each_with_index do |dto, idx|
          dto_as_hash = dto.to_h
          expected_hash = roles_dto_complex[idx]
          expect(dto_as_hash.keys).to match(expected_hash.keys)
          %w[identifier id type owner policy].each do |key|
            expect(dto_as_hash[key]).to eq(expected_hash[key])
          end
          %w[members memberships].each do |key|
            expect(dto_as_hash[key]).to match_array(expected_hash[key]) if expected_hash.key?(key)
          end
          %w[annotations permissions].each do |key|
            expect(dto_as_hash[key]).to match(expected_hash[key]) if expected_hash.key?(key)
          end
        end
      end
    end

    context 'when passed several resource entries as an array of hashes' do
      let(:dtos) { subject.from_hashes(hashes: mapped_resources_complex) }
      it 'should return an array of ResourceDTO structs' do
        expect(dtos.class).to be(Array)
        dtos.each do |dto|
          expect(dto.class).to be(DataObjects::Resource)
        end
      end
      it 'should build identically when called in an array or individually ' do
        dtos.each_with_index do |dto, idx|
          expect(dto).to eq(subject.from_hash(hash: mapped_resources_complex[idx]))
        end
      end
      it 'should return an array of ResourceDTO structs with the correct attributes' do
        dtos.each_with_index do |dto, idx|
          dto_as_hash = dto.to_h
          expected_hash = resources_dto_complex[idx]
          expect(dto_as_hash.keys).to match(expected_hash.keys)
          %w[identifier id type owner policy].each do |key|
            expect(dto_as_hash[key]).to eq(expected_hash[key])
          end
          %w[annotations permitted].each do |key|
            expect(dto_as_hash[key]).to match(expected_hash[key]) if expected_hash.key?(key)
          end
        end
      end
    end
  end

  context 'when is_sensitive is true' do
    context 'and no visible resources are provided' do
      let(:subject) { DataObjects::PrimitiveFactory.new(is_sensitive: true) }
      let(:dto) { subject.from_hash(hash: mapped_roles_simple[0]) }
    
      it 'should return a SensitivePrimitive with a masked identifer and the correct attributes' do
        expect(dto.class).to be(DataObjects::SensitivePrimitive)
        expect(dto.identifier).to eq("cucumber:policy:[REDACTED]")
        expect(dto.type).to eq("policy")

        puts dto

        if dto.respond_to?(:permissions)
          expect(dto.permissions).to be_empty
        end
    
        if dto.respond_to?(:annotations)
          expect(dto.annotations).to be_empty
        end
    
        if dto.respond_to?(:memberships)
          expect(dto.memberships).to be_empty
        end
    
        if dto.respond_to?(:restricted_to)
          expect(dto.restricted_to).to be_empty
        end
      end
    end

    context 'when given a role' do
      let(:subject) { DataObjects::PrimitiveFactory.new(is_sensitive: true, visible_resources: visible_resources) }
      let(:dto) { subject.from_hash(hash: mapped_roles_simple[1]) }

      context 'when it is visible' do
        let(:visible_resources) do
          {
            "cucumber:user:barrett@example" => true
          }
        end

        context 'when its fields are not visible' do
          it 'its fields are redacted' do
            expect(dto.identifier).to eq("cucumber:user:barrett@example")
            expect(dto.owner).to eq("cucumber:policy:[REDACTED]")
            expect(dto.policy).to eq("cucumber:policy:[REDACTED]")
            expect(dto.permissions["execute"]).to eq(["cucumber:variable:[REDACTED]"])
            expect(dto.permissions["read"]).to eq(["cucumber:variable:[REDACTED]"])
            expect(dto.members).to eq(["cucumber:policy:[REDACTED]"])
          end
        end

        context 'when its fields are visible' do
          let(:visible_resources) do
            {
              "cucumber:user:barrett@example" => true,
              "cucumber:policy:example" => true,
              "cucumber:policy:root" => true,
              "cucumber:variable:example/secret01" => true
            }
          end

          it 'its fields are redacted' do
            expect(dto.identifier).to eq("cucumber:user:barrett@example")
            expect(dto.owner).to eq("cucumber:policy:example")
            expect(dto.policy).to eq("cucumber:policy:root")
            expect(dto.permissions["execute"]).to eq(["cucumber:variable:example/secret01"])
            expect(dto.permissions["read"]).to eq(["cucumber:variable:example/secret01"])
            expect(dto.members).to eq(["cucumber:policy:example"])
          end
        end
      end
    end

    context 'when given a resource' do
      let(:subject) { DataObjects::PrimitiveFactory.new(is_sensitive: true, visible_resources: visible_resources) }
      let(:dto) { subject.from_hash(hash: mapped_resources_simple[0]) }

      context 'when it is visible' do
        let(:visible_resources) do
          {
            "cucumber:variable:example/secret01" => true
          }
        end

        context 'when its fields are not visible' do
          it 'is not redacted but its fields are' do
            expect(dto.identifier).to eq("cucumber:variable:example/secret01")
            expect(dto.owner).to eq("cucumber:policy:[REDACTED]")
            expect(dto.policy).to eq("cucumber:policy:[REDACTED]")
            expect(dto.permitted["execute"]).to eq(["cucumber:user:[REDACTED]"])
            expect(dto.permitted["read"]).to eq(["cucumber:user:[REDACTED]"])
          end
        end

        context 'when its fields are visible' do
          let(:visible_resources) do
            {
              "cucumber:user:barrett@example" => true,
              "cucumber:policy:example" => true,
              "cucumber:policy:root" => true,
              "cucumber:variable:example/secret01" => true
            }
          end

          it 'is not redacted but its fields are' do
            expect(dto.identifier).to eq("cucumber:variable:example/secret01")
            expect(dto.owner).to eq("cucumber:policy:example")
            expect(dto.policy).to eq("cucumber:policy:root")
            expect(dto.permitted["execute"]).to eq(["cucumber:user:barrett@example"])
            expect(dto.permitted["read"]).to eq(["cucumber:user:barrett@example"])
          end
        end
      end
    end

    context 'and no visible resources are provided' do
      let(:visible_resources) do
        {
          "cucumber:policy:example" => true
        }
      end
      let(:subject) { DataObjects::PrimitiveFactory.new(is_sensitive: true) }
      let(:dto1a) { subject.from_hash(hash: mapped_roles_simple[0]) }
    
      it 'should return a SensitivePrimitive with a masked identifer and the correct attributes' do
        expect(dto1a.class).to be(DataObjects::SensitivePrimitive)
        expect(dto1a.identifier).to eq("cucumber:policy:[REDACTED]")
        expect(dto1a.type).to eq("policy")

        puts dto1a

        if dto1a.respond_to?(:permissions)
          expect(dto1a.permissions).to be_empty
        end
    
        if dto1a.respond_to?(:annotations)
          expect(dto1a.annotations).to be_empty
        end
    
        if dto1a.respond_to?(:memberships)
          expect(dto1a.memberships).to be_empty
        end
    
        if dto1a.respond_to?(:restricted_to)
          expect(dto1a.restricted_to).to be_empty
        end
      end
    end

    context 'when a policy_id is nil' do
      let(:subject) { DataObjects::PrimitiveFactory.new(is_sensitive: true) }
      let(:hash) do
        {
          "resource_id": "cucumber:policy:example",
          "owner_id": "cucumber:user:admin",
          "created_at": "2024-09-19T21:27:33.052+00:00",
          "policy_id": nil,
          "memberships": [
            {
              "role_id": "cucumber:user:barrett@example",
              "member_id": "cucumber:policy:example",
              "admin_option": true,
              "ownership": true,
              "policy_id": nil
            }
          ],
          "members": [
            {
              "role_id": "cucumber:policy:example",
              "member_id": "cucumber:user:admin",
              "admin_option": true,
              "ownership": true,
              "policy_id": nil
            }
          ]
        }
      end
      
      it 'should not raise an error' do
        expect { subject.from_hash(hash: hash) }.not_to raise_error
      end
    end
  end
end
