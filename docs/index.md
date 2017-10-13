---
title: Conjur by CyberArk
layout: home
section: welcome
id: index
description: Conjur is a scalable, flexible, open source security service that stores secrets, provides machine identity based authorization, and more.
---

# Conjur Features

<div class="feature-wrap">

  <div class="row">
    <div class="col-md-6 feature">
      <img src="/img/feature-icons/machine-identity-teal.svg" alt="Machine Identity icon">
      <h2>Machine Identity</h2>
      Machine Identity is the heart of Conjur. Conjur was designed from the ground up to support security automation workflows of all kinds - secrets management, SSH, traffic authorization, container environments, configuration management, and custom access control scenarios.
    </div>

    <div class="col-md-6 feature">
      <img src="/img/feature-icons/secrets-teal.svg" alt="Secrets Management icon">
      <h2>Secrets Management</h2>
      Conjur provides a policy framework to manage access to secrets. The policy definitions contain no secret themselves, making them safe and easy to share, review, and edit among a group of people without exposing confidential information. With secrets abstraction, even the users of secrets need not know their values.
    </div>

  </div> <!-- /.row -->

  <div class="row">
    <div class="col-md-6 feature">
      <img src="/img/feature-icons/authorization-teal.svg" alt="Authorization icon">
      <h2>Authorization Model</h2>
      Conjur’s machine identity capabilities are built on the foundation of RBAC, ensuring that the automated workloads managed by Conjur are running with proven and scalable security properties. Conjur's policy management can be managed strictly, ensuring that security rules at scale is both tightly managed and scalable.
    </div>

    <div class="col-md-6 feature">
      <img src="/img/feature-icons/scalability-teal.svg" alt="Scalability icon">
      <h2>Scalability</h2>
      Conjur has collected extensive benchmarks of the scale-out performance of Conjur, and can demonstrate linear scaling from clusters of 1 machine to 10 or more. Conjur can demonstrate the fully authenticated, authorized, retrieval of up to 4 million secrets per minute.
    </div>
  </div> <!-- /.row -->

  <div class="row">
    <div class="col-md-6 feature">
      <img src="/img/feature-icons/container-teal.svg" alt="Containers icon">
      <h2>Built for Containers</h2>
      Containers come with their own security challenges and Conjur is specifically built with those in mind. Conjur uniquely identifies containers where each container has its own unique permissions (RBAC) managed by a Conjur root policy. Applications and services running on those containers are also uniquely authenticated and authorized, making sure secrets are shared securely only with their intended recipients.
    </div>

    <div class="col-md-6 feature">
      <img src="/img/feature-icons/integrations-teal.svg" alt="Integrations icon">
      <h2>Integrations</h2>
      CyberArk officially provides and supports integration libraries between Conjur and external tools such as Puppet, Ansible, and Summon, as well as API libraries for Ruby, Go, Java, and .NET. CyberArk has officially partnered with Puppet to provide joint support for the Conjur Puppet Module. CyberArk is extending this partnering relationship to other major tool vendors in the DevOps space.
    </div>
  </div> <!-- /.row -->
</div> <!-- /.feature-wrap -->

# How Conjur Works

To use Conjur, you write policy files to enumerate and categorize the things in your infrastructure: hosts, images, containers, web services, databases, secrets, users, groups, etc. You also use the policy files to define role relationships, such as the members of each group, and permissions rules, such as which groups and machines can fetch each secret. The Conjur server runs on top of the policies and provides HTTP services such as authentication, permission checks, secrets, and public keys. You can also perform dynamic updates, such as change secret values and enroll new hosts.
