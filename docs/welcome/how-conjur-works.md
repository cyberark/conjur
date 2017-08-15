---
title: How Conjur Works
layout: page
section: welcome
---

To use Conjur, you write policy files to enumerate and categorize the things in your infrastructure: hosts, images, containers, web services, databases, secrets, users, groups, etc. You also use the policy files to define role relationships, such as the members of each group, and permissions rules, such as which groups and machines can fetch each secret. The Conjur server runs on top of the policies and provides HTTP services such as authentication, permission checks, secrets, and public keys. You can also perform dynamic updates, such as change secret values and enroll new hosts.

<h1 class="underline">Next Steps</h1>

<div class="row mt-2 equal">
    {% include cta.md id='security' %}
    {% include cta.md id='operations' %}
</div>
