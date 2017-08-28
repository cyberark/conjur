---
title: Tutorial - Java API
layout: page
section: tutorials
---

{% include toc.md key='introduction' %}

The [Conjur API for Java](https://github.com/cyberark/conjur-api-java) provides a robust programmatic interface to Conjur. You can use the Java API to authenticate with Conjur, load policies, fetch secrets, perform permission checks, and more.

{% include toc.md key='prerequisites' %}

* A [Conjur server](/get-started/) endpoint.
* The [Conjur API for Ruby](https://github.com/cyberark/conjur-api-ruby), version 5.0 or later.
* Maven

{% include toc.md key='setup' %}

**Integrating the API**

First, build the API from source with Maven by running the following commands:

```
git clone git@github.com:cyberark/conjur-api-java.git
cd conjur-api-java
mvn package -DskipTests
```

If you are using Maven to manage your project's dependencies, you can run `mvn install` to install the package locally, and then include following dependency in your `pom.xml`:

```
<dependency>
  <groupId>net.conjur.api</groupId>
  <artifactId>conjur-api</artifactId>
  <version>1.2</version>
</dependency>
```

If you aren't using Maven, you can add the `jar` in the normal way. This `jar` can be found in the `target` directory created when you ran `mvn package`.

**Running Tests**

Note that this will not run the integration tests, since these require access to a Conjur instance. To run the integration tests, you will need to define the following environment variables for the `mvn package` command (and remove the `skipTests` property):

```
CONJUR_ACCOUNT=accountName
CONJUR_CREDENTIALS=username:apiKey
CONJUR_APPLIANCE_URL=http://conjur
```

In addition, you will need to load a Conjur policy. Save this file as `root.yml`:

```
- !policy
  id: test
  body:
    - !variable
      id: testVariable
```

To load the policy, use the CLI command `conjur policy load root root.yml`.

{% include toc.md key='creating-instance' %}

A Conjur instance provides access to the individual Conjur services. To create one, you'll need the environment variables as described above. You will typically create a Conjur instance from these values in the following way:

```
Conjur conjur = new Conjur();
```

where the Conjur object is logged in to the account and ready for use.

{% include toc.md key='secrets-fetching' %}

Conjur variables store encrypted, access-controlled data. The most common thing a variable stores is a secret. A variable can have one or more (up to 20) secrets associated with it, and ordered in reverse chronological order.

You will typically add secrets to variables and retrieve secrets from variables in the following way:

```
Conjur conjur = new Conjur();
conjur.variables().addSecret(VARIABLE_KEY, VARIABLE_VALUE);
String retrievedSecret = conjur.variables().retrieveSecret(VARIABLE_KEY);
```

**SSL Certificates**

By default, the Conjur appliance generates and uses self-signed SSL certificates. You'll need to configure Java to trust them. You can accomplish this by loading the Conjur certificate into the Java keystore. First, you'll need a copy of this certificate, which you can get using the [Conjur CLI](https://github.com/cyberark/conjur-cli). Once you've installed the command line tools, you can run

```
conjur init
```

and enter the required information at the prompts. This will save the certificate to a file like `"conjur-mycompany.pem"` in your `HOME` directory. Java doesn't deal with the `.pem` format, so next you'll need to convert it to the `.der` format:

```
openssl x509 -outform der -in conjur-yourcompany.pem -out conjur-yourcompany.der
```

Next, you'll need to locate your JRE home. On my machine it's `/usr/lib/jvm/java-7-openjdk-amd64/jre/`. We'll export this path to `$JRE_HOME` for convenience. If the file `$JRE_HOME/lib/security/cacerts` doesn't exist (you might need to be root to see it), you've got the wrong path for your `JRE_HOME`. Once you've found it, you can add the appliance's cert to your keystore like this:

```
keytool -import -alias conjur-youraccount \
        -keystore "$JRE_HOME/lib/security/cacerts" \
        -file ./conjur-youraccount.der
```

**JAXRS Implementations**

The Conjur API client uses the JAXRS standard to make requests to the Conjur web services. In the future we plan to remove this dependency, but for the time being you may need to change the JAXRS implementation to conform to your environment and application dependencies. For example, in a JBoss server environment, you should use the RESTlet implementation. The Conjur API uses Apache CFX by default. You can replace that dependency in pom.xml to use an alternative implementation.

{% include toc.md key='next-steps' %}

* Read the [Java API code on GitHub](https://github.com/cyberark/conjur-api-java).