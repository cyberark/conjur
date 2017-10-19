---
title: Conjur by CyberArk
layout: home
section: welcome
id: index
description: Conjur is a scalable, flexible, open source security service that stores secrets, provides machine identity based authorization, and more.
---

<div class="container">

  <h2 class="section-title">Conjur Features</h2>

  {% if page.id == "index" %}
    {% include features.html %}
  {% endif %}

</div>

{% if page.id == "index" %}
  {% include enterprise-cta.html %}
{% endif %}


<div class="container">

  <h2 class="section-title">How Conjur Works</h2>
  <p>To use Conjur, you write policy files to enumerate and categorize the things in your infrastructure: hosts, images, containers, web services, databases, secrets, users, groups, etc. You also use the policy files to define role relationships, such as the members of each group, and permissions rules, such as which groups and machines can fetch each secret. The Conjur server runs on top of the policies and provides HTTP services such as authentication, permission checks, secrets, and public keys. You can also perform dynamic updates, such as change secret values and enroll new hosts.</p>

  {% include whatsnew.html %}

</div>
