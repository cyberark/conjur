---
title: CyberArk Conjur
layout: home
section: welcome
id: index
description: Conjur is a scalable, flexible, open source security service that stores secrets, provides machine identity based authorization, and more.
---

<div class="container">
  <div class="landing-page-header">
    <h1>Conjur Open Source</h1>

    <p>
      At Conjur Open Source, we’re building the tools to help you build applications
      safely and securely - <em>without</em> having to be a security expert. From our
      flagship Conjur server (a secret store and RBAC engine), to custom authenticators
      that make the secret zero problem a thing of the past, to Secretless Broker,
      which aims to make sure your apps never have to worry about secrets again.
    </p>
    <p>
      Not sure where to get started? Learn more on
      <a href="https://discuss.cyberarkcommons.org/t/where-should-i-start/65">Discourse</a>,
      where we suggest our favorite guides and tutorials to get up and running.
    </p>
  </div>

  <div id="repo-tabs">

    <ul>
      <li><a href="#repo-tabs-core">Conjur Core</a></li>
      <li><a href="#repo-tabs-integrations">Conjur Integrations</a></li>
      <li><a href="#repo-tabs-last-mile">Last Mile Secrets Delivery</a></li>
    </ul>

    <div id="repo-tabs-core">

      {% assign section = site.data.repositories.core.section %}
      {% assign categories = section.categories %}

      <p>{{ section.description }}</p>

      {% for category in categories %}
        {% assign repos = category.repos %}

        <h2>{{ category.name }}</h2>
        <p>{{ category.description }}</p>

        <ul class="posts">
          {% for repo in repos %}
            <li class="post card">
              {% if repo.image %}
                <img class="post-list-thumb" src="{{ base.url }}/img/repos/{{ repo.thumb }}" alt="{{ repo.image-alt }}">
              {% endif %}
              <div class="post-content">
                <a href="{{ repo.url }}"><h2>{{ repo.name }}</h2><span class="blog-subhead">{{ repo.sub }}</span></a>
                {{ repo.description | strip_html | truncatewords: 40 }}
              </div>
            </li>
          {% endfor %}
        </ul>
      {% endfor %}

    </div>

    <div id="repo-tabs-integrations">

      {% assign section = site.data.repositories.integrations.section %}
      {% assign categories = section.categories %}

      <p>{{ section.description }}</p>

      {% for category in categories %}
        {% assign repos = category.repos %}

        <h2>{{ category.name }}</h2>
        <p>{{ category.description }}</p>

        <ul class="posts">
          {% for repo in repos %}
            <li class="post card">
              {% if repo.image %}
                <img class="post-list-thumb" src="{{ base.url }}/img/repos/{{ repo.thumb }}" alt="{{ repo.image-alt }}">
              {% endif %}
              <div class="post-content">
                <a href="{{ repo.url }}"><h2>{{ repo.name }}</h2><span class="blog-subhead">{{ repo.sub }}</span></a>
                <strong>{{ repo.tool }}:</strong> {{ repo.description | strip_html | truncatewords: 40 }}
              </div>
            </li>
          {% endfor %}
        </ul>
      {% endfor %}

    </div>

    <div id="repo-tabs-last-mile">

      {% assign section = site.data.repositories.delivery.section %}
      {% assign categories = section.categories %}

      <p>{{ section.description }}</p>

      {% for category in categories %}
        {% assign repos = category.repos %}

        <h2>{{ category.name }}</h2>
        <p>{{ category.description }}</p>

        <ul class="posts">
          {% for repo in repos %}
            <li class="post card">
              {% if repo.image %}
                <img class="post-list-thumb" src="{{ base.url }}/img/repos/{{ repo.thumb }}" alt="{{ repo.image-alt }}">
              {% endif %}
              <div class="post-content">
                <a href="{{ repo.url }}"><h2>{{ repo.name }}</h2><span class="blog-subhead">{{ repo.sub }}</span></a>
                {{ repo.description | strip_html | truncatewords: 40 }}
              </div>
            </li>
          {% endfor %}
        </ul>
      {% endfor %}

    </div>

  </div>
</div>

<script>
  $( function() {
    $( "#repo-tabs" ).tabs();
  } );
</script>
