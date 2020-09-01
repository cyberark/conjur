# DAP Deployment Lifecycle Manager  <!-- omit in toc -->

- [Interface](#interface)
  - [Login](#login)
  - [Deploy](#deploy)
    - [Single Cloud/Environment Provisioning](#single-cloudenvironment-provisioning)
    - [Multi Cloud/Environment Provisioning](#multi-cloudenvironment-provisioning)
    - [Phases](#phases)
  - [Actions](#actions)
  - [Cleanup](#cleanup)
- [Tools/Libraries](#toolslibraries)
  - [Testing](#testing)
- [Versioning](#versioning)
- [Packaging](#packaging)



## Interface

This project will include a shell script `bin/provisioner`, to simplify usage. The shell script is a light wrapper around Docker, which encapsulates all functionality.

### Login

Validates credentials, requesting any credentials not found. Login commands can use the on-disc config native to that plat or environment variables. 

```sh
bin/provisioner login aws
bin/provisioner login openshift
```

### Deploy

#### Single Cloud/Environment Provisioning

```sh
bin/provisioner deploy \
  --target aws (<aws|azure|gcp|kubernetes|openshift>) \
  --add-masters 1 \
  --add-master-lb \
  --with-certificates \
  --with-encryption <kms|key-file|hsm>
  --add-followers 2 \
  --add-follower-lb \
  --with-auto-failover \
  --add-dr-standbys 2
  --domain mycompany.org
  --from-backup <backup-file>
```

#### Multi Cloud/Environment Provisioning

```sh
bin/provisioner deploy \
  --target aws \
  --add-masters 1 \
  --add-master-lb
```

```sh
bin/provisioner deploy \
  --target openshift \
  --add-container-followers 3
```

#### Phases

Within each deploy run, one or more of the following stages are run:

- Provision - deploy the required infrastructure for a target
- Prepare - insure DAP container is running and setup as expected
- Configure - insure each node is configured according to the desired end state


### Actions

Actions are changes to the initial state state of the cluster.

```sh
bin/provisioner actions

    --stop-master
    --promote-standby
    --upgrade-to <version>
    --backup
```

### Cleanup

Removes all provisioned resources.

```sh
bin/provisioner cleanup
```

## Tools/Libraries

This proposal does not offer any hard requirements for languages or tools for creating Provisioning and Configuration components (Appendix A does offer some suggests). Specific tool/language choices should meet the following guidelines:

- Components should use tools common to the ecosystem (ex. Prefer Cloud Formation over Cucumber to configure AWS).
- The number of unique tools/languages should be kept to a minimum across components.

Although a new tool can bring value by solving a problem more elegantly, there is a learning cost to the broader team. This cost must be considered when making choices of tools and languages. 

### Testing

Each component should include tests to validate the specific functionality encapsulated by the component.

## Versioning

This tool will be versioned in accordance with the Semantic Versioning specification. A changelog captures all relevant changes between versions.

## Packaging

This tool will be distributed as a versioned Docker image on our internal Docker repository. This insures the tool can be run by all developers and Jenkins without requiring additional dependencies.

This tool will additionally include a versioned shell script to abstract away the Docker implementation details. This script will enable to tool to be called directly from Jenkins.

