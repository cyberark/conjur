# Welcome to Possum

Modern infrastructure is composed of a fluid set of interactiing components such as servers, virtual machines, containers, storage volumes, secrets, job controllers, web services, databases and other code.

To secure this type of infrastructure, it's essential to fully enumerate all of these components, describe their roles and privileges, manage identity at scale, and keep a detailed audit record.

Possum provides:

* **A declarative YAML-based language** to enumerate system components, their roles, privileges and metadata.
* **A REST web service** to:
  * Enroll and revoke identities.
  * List roles and perform permission checks.
  * Submit and store audit records.
* **Integrations** with other popular software in the cloud toolchain such as IaaS, configuration management, continuous integration (CI), container management and cloud orchestration.

# Overview

## Proven

Possum is the direct result of three years of solving real-world problems with companies like Netflix, Cisco, Box, Puppet Labs, Discovery Communications, Rally Software, Ability Networks, Lookout, and SSH Communications Security. 

## Simple to Use

Poussm YAML policies apply powerful role-based access control to familiar infrastructure elements such as users, groups, hosts, groups of hosts, secrets, and web services. 

Possum policies combine these simple, familiar, elements with the primitives of role-based access control: role grants and permissions. An entire infrastructure can be modeled using only 9 elements: policy, user, group, host, layer, variable, web service, role grant, and permission grant. 

Once a policy is loaded, just 6 REST functions are necessary to fully explore and utilize it from the runtime infrastructure: list roles, list resoures, show resource annotations, check a privilege, fetch a secret, and insert an audit record.

For completeness, some additional functions are available such as login, authenticate, rotate API key, etc.

## Powerful

Possum uses Role-based access control, which is a proven model for infrastructure security. Unlike attribute-based access control, role-based access control is fully prescriptive, does not introduce unexpected side-effects from "conveniences" like glob-style attribute patterns, and scales to very large teams through the use of role delegation. 

## Easy to Deploy and Operate

Running Possum is a simple as writing a set of policy files, then running `docker-compose up`. The default backing data store for Possum is Postgresql. You can run the database alongside Possum as a Docker container, or you can use a hosted database service such as AWS RDS.

Possum is also available as `deb` and `rpm` installers, so that you can build custom packaging for your environment (e.g. AMI or VMware images).

## Extensible

Possum can be easily extended by custom services which utilize and/or replace the built-in services. For example, an OAuth2 provider can accept an authenticated request, perform a permission check using the Possum API, and return an appropriate bearer token. An LDAP service can bind remote users, then perform LDAP searches against the underlying Possum policies. A custom authenticator can delegate password-based login to an external Active Directory or LDAP. 

On the client side, Possum is easily programmable using provided libraries for Python, Ruby, Java, Node.js, .Net, Go, and C++. Client libraries can be used to build integrations with tools, such as custom authorization modules and bridges from DevOps tools to secrets mastered in Possum.

# Learn More

* [Quick start]() Create a policy, run Possum in Docker
* [Policy guide](https://developer.conjur.net/policy_guide) Detailed guide to policies
* [REST API reference](http://docs.conjur.apiary.io/) 
* [Client libraries](https://developer.conjur.net/clients) Python, Ruby, Java, Node.js, .Net, and more
* [Command line interface](https://developer.conjur.net/cli)
* [Summon](https://conjurinc.github.io/summon/) Fetch secrets from any secrets server backend and provide them to a sub-process. Works great in a Jenkins job, service run script, and container entry point or sidecar.

