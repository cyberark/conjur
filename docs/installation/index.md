---
title: Installation
layout: page
---

{% include nav-items.md items=site.data.sidebar.main.installation.items %}

# Installation

Installing Conjur is easy on any platform.

## Using the Conjur evaluation service

The evaluation service is the quickest way to get started using Conjur, giving
you immediate access to a running server. However, the evaluation service is
**for developers only** and you should never use it to store production secrets.

If you [create an evaluation account](/try) then you just need to follow the
[client install instructions][client].

## Using your own Conjur server

Running your own Conjur server gives you total control over the software and
doesn't require you to connect to the Internet. First, follow the instructions
to [get your own Conjur server running][server]. Then [install the client
software][client] to connect.

[client]: /get-started/install-conjur-cli
[server]: /get-started/install-conjur-server
