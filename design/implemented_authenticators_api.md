This is a DRAFT

### Personas

|     **Persona**    |                       **Description**                             |
|:---------------:|:-----------------------------------------------------------------:|
| Conjur Operator | A Conjur user with enhanced privileges (loads policies to root, configures authenticators, etc.) |

# Introduction 

## Feature Overview

**As a** Conjur operator\
**I'd like to** know which authenticators are implemented in Conjur\
**So that** I can configure them for users to authenticate

Ideally this data should be managed in our docs but as we don't have yet a fully versioned
documentation, and customers need to know which authenticators are implemented
in the Conjur instance they are using, we will add an API for this. 

### Process Logic

In the following example, the Conjur version includes the authenticators `authn`, `authn-1` & `authn-2`.

- A Conjur Operator runs an `/authenticators` request:\
`GET /authenticators/implemented`
- The user gets a response with code 200 with the following body:
```
{
   “implemented-authenticators”:
   [
      "authn",
      "authn-1",
      "authn-2"
   ]
}
```

### General Analysis

#### Audit 

As the user isn't accessing any resource there is no need to audit in this feature

### Security

#### `/authenticators/implemented` Endpoint

- no need for token as this data is in the docs
