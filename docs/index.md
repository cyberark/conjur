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

{% include toc.md key='vaulting' %}

CyberArk is the leader in enterprise vaulting, whose Enterprise Password Vault (EPV) is adopted by 50% of the Fortune 100. EPV is the most advanced vault available on the market today, protected by 7 layers of security and providing more than 100 automated password rotators. The CyberArk EPV is extended to the cloud by the Conjur replication architecture and machine identity capabilities, which brings vaulted secrets into the cloud in a scalable and secure way. Both CyberArk EPV and Conjur, implement role-based access control, the standard for enterprise security, and both layers of the CyberArk product provide built-in audit collection and reporting.

{% include toc.md key='scalability' %}

Conjur serves client traffic from “followers” which are read-mostly replicas of the authorization rules and vaulted secrets. Conjur followers use a shared nothing architecture, which means that they scale out in a nearly ideal way. Conjur has collected extensive benchmarks of the scale-out performance of Conjur, and can demonstrate linear scaling from clusters of 1 machine to 10 or more. Conjur can demonstrate the fully authenticated, authorized, and audited retrieval of up to 4 million secrets per minute.

{% include toc.md key='integrations' %}

CyberArk officially provides and supports integration libraries between Conjur and external tools such as Active Directory, Puppet, Ansible, Chef, Jenkins, Salt Stack, Docker, Kubernetes, OpenShift, and CloudFoundry. CyberArk has officially partnered with Puppet to provide joint support for the Conjur Puppet Module. CyberArk is extending this partnering relationship to other major tool vendors in the DevOps space.
