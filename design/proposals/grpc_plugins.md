# gRPC Plugins

## Description

This design document describes the design and experience for gRPC based Conjur
plugins.

## Background

Plugins are a pattern to enhance a software system by allowing end-users and
administrators to extend or customize its behavior without modifying the
system source code. Plugins are software components loaded into a system
at runtime, and can be implemented in separate source code repositories.

Conjur currently provides some points for extensibility for authentication
and secrets rotation. However these require the extensions to be implemented
in the Conjur repository and may not be loaded at runtime.

## Technical Approaches

### gRPC plugins

This is the technical approach selected for the detailed design.

#### Advantages

- Plugins run in a separate memory space, and are only able to interact
  with Conjur through explicitly defined interfaces.

- Conjur doesn't need to be restarted to add or remove plugins.

#### Disadvantages

- The infrastructure for metadata, packaging, and lifecycle needs to be
  implementation

### Gem plugins

One option for providing extensions is using Ruby gems.

#### Advantages

- Gems exist in an existing infrastructure for metadata, packaging, distribution
  and installation lifecycle management.

#### Disadvantages

- Adding plugins to the Conjur Ruby load path allows plugins to share the same
  memory spaces as Conjur. This poses a significant risk for 3rd-party code 
  to compromise the security of Conjur.

## User experience

### Conjur administrator experience

#### Plugin discovery

TODO: How do you know what plugins are available?

#### Plugin installation

##### Installation from a repository
```
conjurctl plugin install <plugin path>
```

##### Copying plugin executables into a well-known directory

```
docker run \
...
- v "/plugins/dir/on/host:/opt/conjur/plugins"
...
```

```
cp plugin_executable /plugins/dir/on/host/
```

#### Enabling plugins

```
conjurctl plugin enable plugin_executable
```

This, for example, would add the signature of the executable to an
allow-list of plugins that are trusted to run. **SECURITY** Preventing
executables from being replaced with after installation.

#### Disabling plugins

#### Uninstalling plugins

### Plugin developer experience

- Plugin frameworks
    - golang
    - Ruby?

## Technical Design

### Conjur gRPC plugin registration service

- gRPC

### Conur plugin service

#### Authenticator (existing)

- gRPC service definition

#### Rotator (existing)

- gRPC service definition


#### Policy load controller (future)

##### Mutation controller

- gRPC service definition

##### Validation controller

- gRPC service definition

### Plugin lifecycle

- Conjur starts the plugin executable

    - Conjur provides an access token/certificate to authenticate
      the plugin communication to the gRPC interfaces.

    - Conjur provides a public key to trust for communication from
      the Conjur server.

- The plugin sends a plugin registration to Conjur, providing
  its port

- Conjur registers the plugin's endpoints for authentication, rotation,
  and policy loading.

#### Authentication

- Authentication discovery includes authentications provided by the
  gRPC manager.

- `#authenticate` calls are sent over gRPC to the plugin to return true/false

#### Secret rotation

#### Plugin Load Controllers

##### Mutation

- Modify policy before it's loaded. This allows, for instance, policy templating

##### Validation

- Reject policy that doesn't satisy custome business logic.

## Open questions

- How to verify plugin authenticity? For example, executable signature allow-list.