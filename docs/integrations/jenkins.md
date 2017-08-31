---
title: Jenkins Integration Demo
layout: page
section: integrations
---

The [Jenkins Demo](https://github.com/conjur/jenkins-e2e-example) is an example
of an end-to-end integration of Conjur with Jenkins. It presents two integration
scenarios, one with Conjur and one without, to demonstrate the advantages of
using Conjur for secure secret retrieval. In the Conjur scenario, a Jenkins 
master assumes Conjur machine identity through Conjur's Host Factory 
auto-enrollment system in order to retrieve secrets without having to commit
them to source control.

{% include toc.md key='try-it-out' %}

See the [Jenkins Demo GitHub repo](https://github.com/conjur/jenkins-e2e-example)
for instructions on how to set up and run the demo.
