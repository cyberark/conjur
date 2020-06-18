# Maintaining Requester IP Addresses <!-- omit in toc --> 

When Conjur (or DAP) are run behind a load balancer, users are unable to use CIDR restrictions on Hosts or Layers. Furthermore, Load Balancer IP address appears in Audit logs instead of the true client IP address. This is because Conjur references the last entry in the `X-Forwarded-For` header.

This decision was conscious, and meant to prevent IP spoofing. We have reached a point where customers need a mechanism to add known proxies to Conjur/DAP to identify the true identity of the requesting client. 

This design document is meant to provide a possible solution to the challenge of identifying the client IP while preventing IP spoofing.

- [Current Request Flow](#current-request-flow)
- [Proposed Solution (Summary)](#proposed-solution-summary)
- [Proposed Solution (Detailed)](#proposed-solution-detailed)
  - [Adding Proxies with Policy](#adding-proxies-with-policy)
  - [Limitations](#limitations)
    - [Proxies cannot be layered](#proxies-cannot-be-layered)
- [Rejected Alternatives](#rejected-alternatives)
  - [Configuration using Environment Variables](#configuration-using-environment-variables)

## Current Request Flow

The following visualization offers a typical experience as a requests moves through a Layer 7 load balancers.

![](/design/diagrams/out/proxy-support-overview/proxy-support-overview.png)

As we can see, each load balancer adds its IP address to the `X-Forwarded-For` header.

With our current implementation:
```ruby
# Rack::Request
def ip
  if addr = @env['HTTP_X_FORWARDED_FOR']
    addr.split(',').last.strip
  else
    @env['REMOTE_ADDR']
  end
end
```
the IP address of the last load balancer (`10.2.0.1`) would be used as the request IP.

## Proposed Solution (Summary)
Users can define the proxies in front of a node(s) using Conjur Policy. This enables Conjur to use the first non-proxy IP as the client IP.

## Proposed Solution (Detailed)

### Adding Proxies with Policy

Given the following setup
![](/design/diagrams/out/proxy-master-node/proxy-master-node.png)

we can apply the following policy:
```yaml
- !policy
  id: conjur/settings/proxies
  body:
    - !host 
      id: dap-master.mycompany.com
      annotations:
        proxy/ip-addresses: ['1.2.3.4']
```

With the above proxied request, Conjur will:
1. Check if the `X-Forwarded-For` header has any values. In this example it will have the following string: `10.0.0.1, 1.2.3.4`. 
2. Perform a Regex match using the host ID in the `conjur/settings/proxies` namespace against the request hostname. In this example, we'd match on `dap-master.mycompany.com`.
3. Grab the array of IP addresses stored in the `proxy/ip-addresses` annotation (`['1.2.3.4']`).
4. Starting at the **end** of the list of `X-Forwarded-For` entries, return the first IP address that is not present in the `proxy/ip-addresses` annotation array.
   1. Skip `1.2.3.4`
   2. Return `10.0.0.1`


Performing a Regex match allows fuzzy matching, for example, to apply a single load balancer to all nodes:

```yaml
- !policy
  id: conjur/settings/proxies
  body:
    - !host
      id: '*' # matches any request hostname
      annotations:
        proxy/ip-addresses: ['1.2.3.4', '10.0.0.1']
```

We can also configure multiple hosts to support multiple proxies:

```yaml
- !policy
  id: conjur/settings/proxies
  body:
    - !host 
      id: dap-master.mycompany.com
      annotations:
        proxy/ip-addresses: ['1.2.3.4']

    - !host
      id: dap-follower.us-east-1.mycompany.com
      annotations:
        proxy/ip-addresses: ['10.0.0.21']

    - !host
      id: dap-follower.us-west-1.mycompany.com
      annotations:
        proxy/ip-addresses: ['10.10.0.1']
```

### Limitations

#### Proxies cannot be layered

To simplify the initial implementation, we will not support matches on multiple hosts. Multi-matches would allow more modular declaration. With multi-host matching, we could rewrite the following policy:

```yaml
- !policy
  id: conjur/settings/proxies
  body:
    - !host
      id: dap-follower.zone-1.us-east-1.mycompany.com
      annotations:
        proxy/ip-addresses: ['1.2.3.4', '10.0.0.21']

    - !host
      id: ap-follower.zone-2.us-east-1.mycompany.com
      annotations:
        proxy/ip-addresses: ['1.2.3.4', '10.10.0.1']
```

as:

```yaml
- !policy
  id: conjur/settings/proxies
  body:
    - !host 
      id: '*.us-east-1.mycompany.com'
      annotations:
        proxy/ip-addresses: ['1.2.3.4']

    - !host
      id: dap-follower.zone-1.us-east-1.mycompany.com
      annotations:
        proxy/ip-addresses: ['10.0.0.21']

    - !host
      id: ap-follower.zone-2.us-east-1.mycompany.com
      annotations:
        proxy/ip-addresses: ['10.10.0.1']
```

The above would add the proxy `1.2.3.4` to each of the subsequent hosts.

This adds a substantial amount of complexity to the implementation and is not recommended in the initial version of this functionality.

## Rejected Alternatives

### Configuration using Environment Variables

Although we could accomplish support for proxy IPs with environment variables, environment variables produce a couple of undesirable problems:

- Increases the effort required to setup Conjur/DAP nodes.
- Requires Conjur be restarted if proxy IP addresses change for a particular node.
