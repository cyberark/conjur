#### Note: entity IDs must be URL-encoded

Any identifier included in the URL must be [URL-encoded][percent-encoding] to be
recognized by the Conjur API.

Examples:
| Identifier             | URL-Encoded                |
|------------------------|----------------------------|
| `myapp-01`             | `myapp-01` _(no change)_   |
| `alice@devops`         | `alice%40devops`           |
| `prod/aws/db-password` | `prod%2Faws%2Fdb-password` |
| `research+development` | `research%2Bdevelopment`   |
| `sales&marketing`      | `sales%26marketing`        |

[percent-encoding]: https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding
