---
title: Welcome
layout: page
---

# The banner goes here

* Source Code on Github
* Downloads

* Why use Possum?
* Demo
* Learn More

# And ends here

Modern infrastructure is composed of a fluid set of interacting components such as servers, virtual machines, containers, storage volumes, secrets, job controllers, web services, databases and other code. To properly secure this infrastructure, you need an authoritative
directory service that:

* Enumerates and categorizes everything.
* Assigns roles and permissions to everything.  
* Supports the modern coded workflow.
* Has full support for automation, ephemeral services and containers.
* Is easy to use with other tools in the modern stack.

Possum is the directory and authorization service for the new infrastructure stack, providing:

* **A role-based access policy language** which is used to define system components, their roles, privileges and metadata.
* **A REST web service** to:
  * Enroll and revoke identities.
  * List roles and perform permission checks.
  * Store and serve secrets.
  * Receive and store audit records.
* **Integrations** with other popular software in the cloud toolchain such as IaaS, configuration management, continuous integration (CI), container management and cloud orchestration.

# Why use Possum?

## Proven

Possum has been running in production for more than two years, solving real-world problems at companies like Netflix, Cisco, Box, Puppet Labs, Discovery Communications, Rally Software, Ability Networks, Lookout, and SSH Communications Security. 

In addition, Possum's cryptography has been professionally audited and verified.

## Simple to Use

Each Possum policy is a declarative document which descibes directory elements such as users, groups, hosts, layers (groups of hosts), secrets, and web services. 

Policies then combine these base elements with statements of role-based access control: role grants and permissions. An entire infrastructure can be modeled using only 9 elements: policy, user, group, host, layer, variable, web service, role grant, and permission grant. 

Once a policy is loaded, just 6 REST functions are necessary to fully explore and utilize it from the runtime infrastructure: list roles, list resoures, show resource annotations, check a privilege, fetch a secret, and insert an audit record.

For completeness, some additional functions are available, for example login, authentication, and API key rotation.

Policies are defined in YAML files which are easy for both people and machines to read and understand. It's easy to write code to generate policies, and to read and interpret them in any programming language.

## Powerful

Possum uses Role-based access control, which is a proven model for infrastructure security. Unlike attribute-based access control, role-based access control is fully prescriptive, does not introduce unexpected side-effects from "conveniences" like glob-style attribute patterns, and scales to very large teams through the use of role delegation. 

## Easy to deploy and operate

Running Possum is as simple as `docker-compose up`. The default backing data store for Possum is Postgresql. You can run the database alongside Possum as a Docker container, or you can use a hosted database service such as AWS RDS.

## Comprehensive

Possum provides a authoritative answers to essential authorization questions such as:

* Can application X obtain a SSL certificate with subject name Y?
* Can code in application X make an HTTP POST request to service Y?
* What is the SSH public key of user X?
* Can application X access the password for database Y?
* Is user X allowed to SSH to machine Y? If so, what is the privilege level (Unix group) of the user on the machine?
* Can machine X attach volume Y?
* Can user or job X launch a container or VM from image Y?

## Extensible

Possum can be easily extended by custom services which utilize and/or replace the built-in services. For example, an OAuth2 provider can accept an authenticated request, perform a permission check using the Possum API, and return an appropriate bearer token. An LDAP service can bind remote users, then perform LDAP searches against the underlying Possum policies. A custom authenticator can augment the Possum `login` route by delegating to an external Active Directory or LDAP. 

On the client side, Possum is easily programmable by interacting with the REST API. This capability can be used to provide custom authentication and authorization for popular DevOps tools.

# Demo

## Start Possum

In the `demo` directory there's a `start.sh` script which uses docker-compose to run a Possum container and a Postgresql database. First, enter the demo directory:

{% highlight shell %}
possum $ cd demo
{% endhighlight %}

Possum requires a master encryption key. Generate and store the master encryption key:

{% highlight shell %}
possum/demo $ export POSSUM_DATA_KEY="$(docker-compose run --rm possum data-key generate)"
Creating demo_pg_1
possum/demo $ echo $POSSUM_DATA_KEY
A3rUTu+WXF0QN0ZvikIVsnbcygx8a3sOpC+dGRg8n3k=
{% endhighlight %}

Now, run Possum using `docker-compose`:

{% highlight shell %}
possum/demo $ docker-compose up -d
Creating demo_pg_1
Creating demo_possum_1
Creating demo_watch_1
{% endhighlight %}

Then you can check the status:

{% highlight shell %}
possum/demo $ docker-compose ps
    Name                   Command               State                Ports              
----------------------------------------------------------------------------------------
demo_pg_1       /docker-entrypoint.sh postgres   Up       5432/tcp                       
demo_possum_1   possum server -f /run/poss ...   Up       80/tcp                         
demo_watch_1    possum policy watch /run/p ...   Up       80/tcp
{% endhighlight %}

## A brief description of policies

Possum policies are used to define the infrastructure elements, their roles, and the permissions between them. Typical elements include:

* **User** A user.
* **Group** A group.
* **Host** A machine actor, such as a server, VM, container, job, script, or PaaS application.
* **Layer** A group of hosts.
* **Webservice** A protected service such as a REST web service
* **Variable** An encrypted piece of data, such as a database password, cloud credential, or SSL private key.

Policies also include:

* **Grant** Gives a role, such as a Layer, to another role, such as a Host.
* **Permit** Gives a permission, such as `read` or `execute` on a protected element, such as a Host or Variable, to a role, such as a Group or Host.

## Use Possum

The Possum server that you are running contains some example policies. Here are some examples of things that you can do with it.

### Permission checks

#### Check whether a user can push to a container registry

#### Check whether an app can push to a container registry

#### Check whether an app is allowed to call a custom web service

#### Check whether an app can run a container

#### Check a user's privilege to a host

### Public keys

#### Fetch a user's public keys

### Resource enumeration

#### List all the hosts

#### List all the groups

### Role memberships

#### List the roles of a user

#### List the roles of an app

# Learn More

* [Demos](demos.html) See how to run the Possum service and make typical REST calls.
* [Documentation](docs.html) 
* [REST API reference]() 
* [Downloads]() Client library and CLI
