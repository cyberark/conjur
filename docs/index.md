---
title: CyberArk Conjur
layout: page
section: welcome
id: index
redirect_from: "/start"
---

<div class="row equal">
    {% include cta.md id='local' %}
    {% include cta.md id='hosted' %}
</div>

{% include toc.md key='machine-identity' %}

Machine Identity is the heart of CyberArk Conjur. It was designed from the ground up to support security automation workflows of all kinds - secrets management, SSH, traffic authorization, container environments, configuration management, and custom access control scenarios.

{% include toc.md key='authorization' %}

Both CyberArk EPV and Conjur implement full role-based access control (RBAC), the proven standard in enterprise security. Conjur’s machine identity capabilities are built on the foundation of RBAC, ensuring that the automated workloads managed by Conjur are running with proven and scalable security properties. Conjur’s machine identity rules are managed using declarative documents called policies. Policy management can be federated across an organization in a strictly managed way, ensuring that management of Conjur security rules at scale is both tightly managed and scalable from the standpoint of organizational size.

{% include toc.md key='secrets' %}

Conjur provides a policy framework to manage access to secrets. The policy definitions contain no secret themselves, making them safe and easy to share, review, and edit among a group of people without exposing confidential information.

With secrets abstraction, even the users of secrets need not know their values. By separating development, test, and production rules, policies can be tested in each environment with different secrets and rolled to production with confidence that the application is protected by a least privilege model.

{% include toc.md key='scalability' %}

Conjur serves client traffic from “followers” which are read-mostly replicas of the authorization rules and vaulted secrets. Conjur followers use a shared nothing architecture, which means that they scale out in a nearly ideal way. Conjur has collected extensive benchmarks of the scale-out performance of Conjur, and can demonstrate linear scaling from clusters of 1 machine to 10 or more. Conjur can demonstrate the fully authenticated, authorized, and audited retrieval of up to 4 million secrets per minute.

{% include toc.md key='integrations' %}

CyberArk officially provides and supports integration libraries between Conjur and external tools such as Active Directory, Puppet, Ansible, Chef, Jenkins, Salt Stack, Docker, Kubernetes, OpenShift, and CloudFoundry. CyberArk has officially partnered with Puppet to provide joint support for the Conjur Puppet Module. CyberArk is extending this partnering relationship to other major tool vendors in the DevOps space.
