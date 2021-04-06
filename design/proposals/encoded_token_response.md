# Encoded Token Response - Solution Design

## Table of Contents
- [Encoded Token Response - Solution Design](#encoded-token-response---solution-design)
  * [Table of Contents](#table-of-contents)
  * [Glossary](#glossary)
  * [Useful links](#useful-links)
  * [Background](#background)
  * [Issue description](#issue-description)
    + [Solution](#solution)
    + [Option A - Accept HTTP Headers](#option-a---accept-http-headers)
      - [Design](#design)
      - [Backwards compatibility](#backwards-compatibility)
      - [Notes](#notes)
    + [Option B - URL Patten](#option-b---url-patten)
      - [Design](#design-1)
      - [Backwards compatibility](#backwards-compatibility-1)
    + [Omitted Solutions](#omitted-solutions)
    + [Preferred Solution](#preferred-solution)
  * [Security](#security)
  * [Test Plan](#test-plan)
  * [Documentation](#documentation)
  * [Open questions](#open-questions)

## Glossary

| **Term** | **Description**  |
|----------|------------------|
| encoded  |base64 encoded    |
| JWS      |json web signature|
| JWT      |json web token    |


## Useful links
1. [HTTP Content Negotiation Best Practices](https://restfulapi.net/content-negotiation/)
2. MDN web docs:
    1. [HTTP Accept Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept)
    2. [HTTP Accept-Encoding Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding)
    3. [HTTP Content-Type Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type)
    4. [HTTP Content-Encoding Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Encoding)
3. [Rails Routing Guides](https://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments)
4. [Correct Usage of JSON](https://stackoverflow.com/questions/477816/what-is-the-correct-json-content-type)

## Background

When a Conjur identity sends authentication request to `authn` authenticator (for example), it receives a JWT access token.
An example for optional HTTP session flow: 

![alt text](encoded_token_chart.jpeg "Login process")

Current authentication response is a Flattened JWS JSON Serialization, e.g:
```json
{
    "protected": "eyJh...",
    "payload": "eyJz...",
    "signature": "CZgB..."
}
``` 

In order to use this token for restricted endpoint it **must** be encode and added to `Authorization: Token token=` header:
```sh
echo "Get Conjur access token using an Azure access token"
# Get an authn-azure Conjur access token for host azure-apps/test-app
authn_azure_response=$(curl -k -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data "jwt=$azure_access_token" \
  https://"$CONJUR_SERVER_DNS":8443/authn-azure/test/cucumber/host%2Fazure-apps%2Ftest-app/authenticate)

# Explicit Encoding of the JWT from the response 
authn_azure_access_token=$(echo -n "$authn_azure_response" | base64 | tr -d '\r\n')

echo "Retrieve a secret using the Conjur access token"
# Retrieve a Conjur secret using the authn-azure Conjur access token
secret=$(curl -k -H "Authorization: Token token=\"$authn_azure_access_token\"" \
  https://"$CONJUR_SERVER_DNS":8443/secrets/cucumber/variable/secrets/test-variable)

echo "Retrieved secret ${secret} from Conjur!!!"
```
[Code reference](https://github.com/cyberark/conjur/blob/application_identity_validation/ci/authn-azure/run-authn-azure.sh#L16)


The requested situation is to support both response of current **Flattened** JWS JSON Serialization with content type `application/json` and encoded JWS **Compact** Serialization with content type `text/plain`. 

## Issue description
1. HTTP server best practices: Using `application/json` as the content type to encoded output (not a JSON) is bad practice.
    So encoded output shouldn't use `application/json` unless it will be in JSON format. 
    The `../autheticate` response is in JSON format so it makes sense to use `application/json` as the response content type.
        As well as `../login`,  which returns the api key as `text/plain`.

##  Solution
Such behaviour can be implemented in many ways. In this section, 2 main options will be presented (including some omitted options).    
### Option A - Accept HTTP Headers
According to [MDN web docs](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept):
 > The `Accept` request HTTP header advertises which content types the client is able to understand. Using content negotiation, the server then selects one of the proposals, uses it and informs the client of its choice with the `Content-Type` response header.

To conclude, we can choose the response's `Content-Type` by the request's `Accept` header.

We can add the usage of `Accept-Encoding` HTTP header, which advertises which content type encoding the client is able to understand.
The server will return the encoded response with the header `Content-Encoding: base64` to make it clear that the chosen encoding method is base64.  

#### Design
When `../authenticate` request the response will be encoded **only** if the `-H Accept: text/plain` and `"Accept-Encoding: base64"`.
Otherwise, returns json access token as `application/json`.

```ruby
def authenticate
    # get the authn access token
    content_type = (request.headers["Accept"] == "text/plain" && request.headers["Accept-Encoding"] == "base64") ? :text : :json
    # encode Base64 if needed
    render content_type => auth_token
```
#### Backwards compatibility
Default behaviour: Only if the `Accept` is set to `text/plain` the response will be encoded.

#### Notes
* Default behaviour causes that all other `Accept` content-types (and their encodings) are ignored (By requesting 
`../authenticate` with `Accept: "xml", Accept-Encoding: "gzip"` will return decoded `application/json`).

### Option B - URL Patten
According to [Rails Routing Guides](https://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments)  we can use wildcards to suggests the requested `Content_type`.

By requesting `../authenticate.encoded` the output will be encoded access token.

#### Design
When `../authenticate` request the response will be encoded **only** if the url suffix (wildcard) is `.encoded`.
Otherwise, returns json access token as `application/json`

```ruby
def authenticate
    # get the authn access token
    # extract the url suffix
    content_type = ( params[:format] == "encoded") ? :text : :json
    # encode Base64 if needed
    render content_type => auth_token
```
#### Backwards compatibility
By adding `format: true` to the endpoint, it makes the wildcard **mandatory**. Which means that previous `../authenticate`
request **will fail** unless we take care of non-format requests (can be done by adding a route without format or `respond_to` and `respond_with` keywords).

### Omitted Solutions
* **Optional Parameters** - By passing an optional parameter (`../authenticate?encoded=true` e.g.) which requires 
an encoded response. This solution is not popular in Conjur because the server doesn't use url optional parameters.  

* **New Endpoint** - By requesting to a new endpoint (`../authenticate/encoded` e.g.) the response will be encoded. This 
solution is a redundant overhead which can (and should) be avoided. 

### Preferred Solution
Even though, rails routing guidelines suggests that it supports response's content type based on wildcard suffix,
I prefer the `Accept` HTTP header solution. This solution is is more accurate from content negotiation point of view.
The suffix based solution is less complicated but it makes the request seems like it ask for a file (which ends with a 
certain suffix) rather than a dynamic content type handling. The `Accept` method is more like a contract between the client 
and server - in our case the client accepts `text/plain` response causes the server to send an encoded token. 

## Security
TBD

## Test Plan

1. Tests should be on Conjur Enterprise and Conjur OSS (HTTPS vs HTTP).
2. All previous tests of `authenticate` method should passed.
3. Perform performance test (Check for possible degradation) 

| **Title** | **Given** | **When** | **Then** | **Comment** |
|-----------|-----------|----------|----------|-------------|
| Successful encoded token response           | Credentials          | I send an authenticate request          |  I get an encoded valid token        | Authenticate using the chosen method. Also test with Accept-Encoding which is only base64 and includes base64|
| Successful json token response             | Credentials           | I send an authenticate request with Accept-Encoding header which isn't base64   | I get a decoded valid token  | relevant to solution 1 | 
| Failed authenticate request works          | Wrong credentials          | I send an authenticate request         | I get the same response as decode flow         |             |


## Documentation
- [ ] Add documentation about new API ability

## Open questions
* Conjur server profile - Should we define conventions about Conjur sessions (requests and response content types)?
* Audit/ Logs- Do we need to document successful encoded token requests in a special way?

