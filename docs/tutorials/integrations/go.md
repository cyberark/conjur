---
title: Tutorial - Go API
layout: page
section: tutorials
---

{% include toc.md key='introduction' %}

The [Conjur API for Go](https://github.com/cyberark/conjur-api-go) provides a programmatic interface to Conjur. You can use the Go API to authenticate with Conjur, load policies, and fetch secrets.

{% include toc.md key='prerequisites' %}

* A [Conjur server](/get-started/) endpoint.
* The [Conjur API for Go](https://github.com/cyberark/conjur-api-go)

{% include toc.md key='setup' %}

Clone the Conjur API GitHub repository or use your Golang dependency manager of choice.

```
go get -u cyberark/conjur-api-go
```

{% include toc.md key='configuration' %}

You can load the Conjur configuration from your environment using the following Go code:

import "github.com/conjurinc/api-go/conjurapi"

```
config := conjurapi.Config{
    Account:      os.Getenv("CONJUR_ACCOUNT"),
    ApplianceURL: os.Getenv("CONJUR_APPLIANCE_URL"),
}
        
conjur, err := conjurapi.NewClientFromKey(
    config: config, 
    Login:  os.Getenv("CONJUR_AUTHN_LOGIN"),
    APIKey: os.Getenv("CONJUR_AUTHN_API_KEY"),
)
```

{% include toc.md key='secret-retrieval' %}

Authenicated clients are able to retrieve secrets:

```
secretValue, err := conjur.RetrieveSecret(variableIdentifier)
if err != nil {
// error handling
}
// do something with the secretValue
```

{% include toc.md key='next-steps' %}

* Read the [Go API code on GitHub](https://github.com/cyberark/conjur-api-go).