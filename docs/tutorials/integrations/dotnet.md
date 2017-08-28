---
title: Tutorial - .NET API
layout: page
section: tutorials
---

{% include toc.md key='introduction' %}

The [Conjur API for .NET](https://github.com/cyberark/conjur-api-dotnet) provides a robust, programmatic interface to Conjur. You can use the .NET API to authenticate with Conjur, fetch secrets, and use a host factory token to allow a host to communicate with Conjur.

{% include toc.md key='prerequisites' %}

* A [Conjur server](/get-started/) endpoint.
* The [Conjur API for .NET](https://github.com/cyberark/conjur-api-dotnet)
* Visual Studio

{% include toc.md key='building' %}

This sample was built and tested with Visual Studio 2015.

First, load the `api-dotnet` solution in Visual Studio by selecting Open > Project/Solution > api-dotnet.sln from the Visual Studio file menu. Next, build the solution to create:

```
- conjur-api.dll: the .NET version of the Conjur API.
- ConjurTest.dll: test DLL used for automated testing of the Conjur .NET API
- example.exe: sample application that uses the Conjur API.
```

Alternatively, you may wish to build the project in a Docker container, in which case we recommend using Mono and xbuild.

{% include toc.md key='example' %}

To run the `example` project in Visual Studio, first set it as the Startup Project by right-clicking `example` in the Solution Explorer and selecting "Set as Startup Project". You must then configure the project to run with the following arguments:

```
Usage: Example  <applianceURL>
                <applianceCertificatePath>
                <username> 
                <password> 
                <variableId>
                <hostFactoryToken>
```

- `applianceURL`: The appliance URL, including `/api` e.g. `https://conjurmaster.myorg.com/api`

- `applianceCertificatePath`: The path and name of the Conjur appliance certificate. The easiest way to get the certifiate is to use the Conjur CLI command `conjur init -h conjurmaster.myorg.com -f .conjurrc`. The certificate can be taken from any system you have run the Conjur CLI from.

- `username`: The username of a Conjur User or the hostname of a Conjur Host.

- `password`: The password of a Conjur user or the API key of a Conjur Host.

- `variableId`: The name of an existing variable in Conjur that has a value set and for which the username has execute permissions.

- `hostFactoryToken`: The easiest way to get a Host Factory token for testing is to add a Host Factory to a Layer using the Conjur CLI commands `conjur hostfactory create` and `conjur hostfactory token create`. Use the token returned from that call as the value for this parameter.

{% include toc.md key='next-steps' %}

* Read the [.NET API code on GitHub](https://github.com/cyberark/conjur-api-dotnet).
