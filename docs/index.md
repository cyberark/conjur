---
title: CyberArk Conjur Community Edition
layout: page
section: welcome
id: index
redirect_from: "/start"
---

<div class="row equal">
    {% include cta.md id='local' %}
    {% include cta.md id='hosted' %}
</div>

# Conjur Features

<div class="feature-wrap">

  <div class="row">
    <div class="col-md-6 feature">
      <img src="/img/feature-icons/machine-identity.svg" alt="Machine Identity icon">
      <h2>Machine Identity</h2>
      Machine Identity is the heart of CyberArk Conjur. Conjur was designed from the ground up to support security automation workflows of all kinds - secrets management, SSH, traffic authorization, container environments, configuration management, and custom access control scenarios.
    </div>

    <div class="col-md-6 feature">
      <img src="/img/feature-icons/secrets-key.svg" alt="Secrets Management icon">
      <h2>Secrets Management</h2>
      Conjur provides a policy framework to manage access to secrets. The policy definitions contain no secret themselves, making them safe and easy to share, review, and edit among a group of people without exposing confidential information.

      With secrets abstraction, even the users of secrets need not know their values. By separating development, test, and production rules, policies can be tested in each environment with different secrets and rolled to production with confidence that the application is protected by a least privilege model.
    </div>

  </div> <!-- /.row -->

  <div class="row">
    <div class="col-md-6 feature">
      <img src="/img/feature-icons/authorization-icon.svg" alt="Authorization icon">
      <h2>Authorization Model</h2>
      Conjur’s machine identity capabilities are built on the foundation of RBAC, ensuring that the automated workloads managed by Conjur are running with proven and scalable security properties. Conjur’s machine identity rules are managed using declarative documents called policies. Policy management can be federated across an organization in a strictly managed way, ensuring that management of Conjur security rules at scale is both tightly managed and scalable from the standpoint of organizational size.
    </div>

    <div class="col-md-6 feature">
      <img src="/img/feature-icons/scalability-icon.svg" alt="Scalability icon">
      <h2>Scalability</h2>
      Conjur has collected extensive benchmarks of the scale-out performance of Conjur, and can demonstrate linear scaling from clusters of 1 machine to 10 or more. Conjur can demonstrate the fully authenticated, authorized, and audited retrieval of up to 4 million secrets per minute.
    </div>
  </div> <!-- /.row -->

  <div class="row">
    <div class="col-md-6 feature">
      <img src="/img/feature-icons/containers-icon.svg" alt="Containers icon">
      <h2>Built for Containers</h2>
      Containers come with their own security challenges and Conjur is specifically built with those in mind.  Conjur uniquely identifies and audits containers and each container has its own unique permissions (RBAC) managed by a Conjur root policy. Applications and services running on those containers are also uniquely authenticated and authorized, making sure secrets are shared securely only with their intended recipients.
    </div>

    <div class="col-md-6 feature">
      <img src="/img/feature-icons/integrations-icon.svg" alt="Integrations icon">
      <h2>Integrations</h2>
      CyberArk officially provides and supports integration libraries between Conjur and external tools such as Puppet, Ansible, and Summon, as well as APIs for Ruby, Go, Java, and .NET. CyberArk has officially partnered with Puppet to provide joint support for the Conjur Puppet Module. CyberArk is extending this partnering relationship to other major tool vendors in the DevOps space.
    </div>
  </div> <!-- /.row -->

</div> <!-- /.feature-wrap -->
