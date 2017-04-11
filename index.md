---
layout: page
---

Possum is the security service for modern infrastructure, providing:

* Machine identity.
* Secrets vault.
* Officially supported integrations with popular DevOps and cloud tools.

# How does Possum work?

< diagram here >

To use Possum, you write policy files to enumerate and categorize the things in your infrastructure : hosts, images, containers, web services, databases, secrets, users, groups, etc. You also use the policy files to define role relationships, such as the members of each group, and permissions rules, such as which groups and machines can fetch each secret. The Possum server runs on top of the policies and provides HTTP services such as authentication, permission checks, secrets, and public keys. You can also perform dynamic updates to the infrastructure, such as change secret values and enroll new hosts.

# Why use Possum?

## Complete

Possum provides a complete solution to secrets management for DevOps. What do we mean by this?
It's not just a tool that you have to figure out how to deploy and operationalize.
Possum comes with everything you need from basic setup instructions, pre-built
and officially maintained integrations with the other DevOps software in your toolchain, 
to HA instructions and strategies that are easy to operationalize.

With Possum, you CAN solve your secrets management problem quickly and easily.

## Proven

Possum has been running in production for more than two years, solving real-world problems at companies like Cisco, Box, Puppet Labs, Discovery Communications, Ability Networks, Lookout, and Machine Zone. 

In addition, Possum's cryptography has been professionally audited and verified.

## Simple to Use

You can define your entire infrastructure using only 9 elements: policy, user, group, host, layer, variable, web service, role grant, and permission grant. And with just 5 REST functions you can authenticate, search, fetch secrets, perform permission checks, and fetch public keys.

Policies are defined using YAML, which is easy for both people and machines to read and understand. 

## Powerful

Possum provides full role-based access control, which is a proven model for infrastructure security. Unlike attribute-based access control, role-based access control is not susceptible to unexpected side-effects, and it scales very well to large systems through the use of role delegation. 

## Easy to deploy and operate

Running Possum is as simple as `docker-compose up`. The default backing data store for Possum is Postgresql. You can run the database alongside Possum as a Docker container, or you can use a hosted database service such as AWS RDS.

## Programmable

Possum is easily programmable by interacting with the REST API. This capability can be used to provide custom authentication and authorization for popular DevOps tools.

