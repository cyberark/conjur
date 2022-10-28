# Extensions

Extensions allow for low-level integration with Conjur application lifecycle
events. This is useful for detailed automation and application extensions (e.g.
Enterprise Conjur services).

Extensions are an experimental feature and each group of available extension
points is currently disabled by default and may be enabled with a
[feature flag](./feature_flags.md).

## Functional Overview

Extensions are implemented as Ruby source code, co-located by the Conjur
application server. Extensions are added as subdirectories under
`{conjur-base-directory}/extensions`. The name of the extension is the name of the
subdirectory. For example, an extension named `my-extension` must live in the
subdirectory `{conjur-base-directory}/extension/my-extension`).

The entrypoint for a Conjur extension is a Ruby source file (`*.rb`) that also
uses the extension name as the filename. So the entrypoint for `my-extension`
must be located at
`{conjur-base-directory}/extension/my-extension/my-extension.rb`.

The extension entry point may load other Ruby source files that implement the
extension, and registers individual classes with Conjur that implement
particular extension points.

Finally, for Conjur to auto-load an extension, it must be enabled in the Conjur
config with either the `CONJUR_EXTENSIONS` environment variable or the
`extensions` value in the `conjur.yml` configuration file. The environment
variable must be a comma-delimited list of extensions name. The value in the
`conjur.yml` config may either be a comma-delimited string or a YAML array of
extension names.

### Define a new extension

To create a new extension (e.g. `my-extension`), create both a subdirectory
and Ruby source file using the extension name under
`{conjur-base-directory}/extensions`. For example:

```sh
{conjur-base-directory}/extension/my-extension/my-extension.rb
```

This source file is the extension entry point. It is used to:

- Load other required Ruby source files
- Register extension classes with Conjur

For example:

```ruby
# {conjur-base-directory}/extension/my-extension/my-extension.rb

require_relative 'my-extension-implementation'

Conjur::Extension::Repository.register(
  kind: :a_conjur_extension_point,
  implementation_class: MyExtensionImplementation
)
```

### Enable an extension

There are two ways to allow Conjur to load an extension when it runs:

- **Use `CONJUR_EXTENSIONS` environment variable**

  The variable value must be a comma delimited string of extension names. For
  example, to set the variable on a Docker container:

  ```sh
  docker run ... -e 'CONJUR_EXTENSIONS=my-extension,some-other-extension' ...
  ```

- **Use the `conjur.yml` config file**

  Alternatively, the extensions may be set in the Conjur config file, such as:

  ```yaml
  ...
  extensions:
    - my-extension
    - some-other-extension
  ...
  ```

  After updating the config file, the configuration must be applied in Conjur
  with the following command in the Conjur container:

  ```sh
  conjurctl configuration apply
  ```

## Available Extension Points

### Policy Load Callbacks

Policy load callback extension classes receive event method calls during Conjur
policy load orchestration.

#### **Feature flag**

Policy load callbacks are enabled with the feature flag
`CONJUR_FEATURE_POLICY_LOAD_EXTENSIONS`.

#### **Extension registration**

Policy load callback extension classes are registered registered with the kind
`:policy_load`. For example:

```rb
Conjur::ExtensionRepository.register(
  kind: :policy_load,
  implementation_class: ...
)
```

#### **Available events**

- `before_load_policy`, `after_load_policy`

  Events before and after the policy load context (temporary database schema)
  is created and dropped.

  Arguments: `policy_version`

- `after_create_schema`

  Emitted after the temporary database schema is initialized.

  Arguments: `policy_version`, `schema_name`

- `before_insert`, `after_insert`

  Emitted before and after new records are inserted into the primary database
  schema.

  Arguments: `policy_version`, `schema_name`

- `before_update`, `after_update`

  Emitted before and after existing records are updated in the primary database
  schema.

  Arguments: `policy_version`, `schema_name`

- `before_delete`, `after_delete`

  Emitted before after records are deleted from the primary database schema.

  Arguments: `policy_version`, `schema_name`

### Roles API Callbacks

Roles API callback extension classes receive event method calls when role
members are added or removed using the Conjur REST API.

#### **Feature flag**

Roles API callbacks are enabled with the feature flag
`CONJUR_FEATURE_ROLES_API_EXTENSIONS`.

#### **Extension registration**

Roles API callback extension classes are registered registered with the kind
`:roles_api`. For example:

```rb
Conjur::ExtensionRepository.register(
  kind: :roles_api,
  implementation_class: ...
)
```

#### **Available events**

- `before_add_member`

  Emitted before a member is added to a role with the Conjur REST API.

  Arguments: `role`, `member`

- `after_add_member`

  Emitted after a member is added to a role with the Conjur REST API.

  Arguments: `role`, `member`, `membership`

- `before_delete_member`, `after_delete_member`

  Emitted before and after a member is removed from a role with the Conjur REST
  API.

  Arguments: `role`, `member`, `membership`
