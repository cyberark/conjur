# Maintaining Requester IP Addresses <!-- omit in toc --> 

When Conjur (or DAP) are run behind a load balancer, users are unable to use CIDR restrictions on Hosts or Layers. Furthermore, Load Balancer IP address appears in Audit logs instead of the true client IP address. This is because Conjur references the last entry in the `X-Forwarded-For` header.

This decision was conscious, and meant to prevent IP spoofing. We have reached a point where customers need a mechanism to add known proxies to Conjur/DAP to identify the true identity of the requesting client. 

This design document is meant to provide a possible solution to the challenge of identifying the client IP while preventing IP spoofing.

- [Current Request Flow](#current-request-flow)
- [Proposed Solutions](#proposed-solutions)
  - [Policy Based Proxies](#policy-based-proxies)
    - [Proposed Solution (Summary)](#proposed-solution-summary)
    - [Proposed Solution (Detailed)](#proposed-solution-detailed)
      - [Adding Proxies with Policy](#adding-proxies-with-policy)
      - [Limitations](#limitations)
        - [Proxies cannot be layered](#proxies-cannot-be-layered)
  - [Node-based Configuration](#node-based-configuration)
    - [Proposed Solution (Summary)](#proposed-solution-summary-1)
    - [Proposed Solution (Detailed)](#proposed-solution-detailed-1)
      - [Adding/Changing Proxies](#addingchanging-proxies)
    - [Advantages](#advantages)
    - [Disadvantages](#disadvantages)

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

## Proposed Solutions

### Policy Based Proxies

#### Proposed Solution (Summary)
Users can define the proxies in front of a node(s) using Conjur Policy. This enables Conjur to use the first non-proxy IP as the client IP.

#### Proposed Solution (Detailed)

##### Adding Proxies with Policy

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

##### Limitations

###### Proxies cannot be layered

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

### Node-based Configuration

#### Proposed Solution (Summary)

An alternative to the policy based approach is to configure each node with support for one or more proxies. We'll accomplish this using a DAP configuration file or alternatively, an environment variable.

#### Proposed Solution (Detailed)

Given the following setup
![](/design/diagrams/out/proxy-master-node/proxy-master-node.png)


Given a request from a client (IP: `10.0.0.1`) which has proxies through a load balancer (IP: `1.2.3.4`) to a particular Follower, we'd expect the following `X-Forwarded-For` header:

```
10.0.0.1, 1.2.3.4
```

Given a DAP instance is configured with the Following DAP configuration:
```json
# config/dap.json
{
  "conjur": {
    "proxies": [10.10.0.1, 1.2.3.4]
  }
}
```

and loaded during the initial Master configuration:

```sh
$ evoke configure master \
    --json-attributes-file config/dap.json
    ...
```

or to uses the environment variable:

```sh
$ CONJUR_PROXIES=10.10.0.1,1.2.3.4 evoke configure master \
    ...
```

Given a CIDR restricted Host or User:

```yml
- !host

  id: my-host
  restricted_to: [10.0.0.1]

- !user
  id: my-user
  restricted_to: [10.0.0.1]
```

Then:

- Audit events record the client IP as `10.0.0.1`
- Hosts or Users with the `restricted_to` filter `restricted_to: [10.0.0.1]` can authenticate

To support this, we'll need to update the `Rack::Request#ip` method from:

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

to something like:

```ruby
# Rack::Request
def ip
  if addr = @env['HTTP_X_FORWARDED_FOR']
    proxies = ENV['CONJUR_PROXIES'] || config.conjur.proxies
    addr.split(',').reverse.drop_while { |ip_addr| proxies.include?(ip_addr) }.first
  else
    @env['REMOTE_ADDR']
  end
end
```

Which returns the first entry not in the proxies list.

##### Adding/Changing Proxies

If a new load balancer is added upstream, the node can be updated with the following:

```sh
$ evoke evoke variable set CONJUR_PROXIES 10.10.10.10,1.2.3.4

```

Which updates the `CONJUR_PROXIES` environment variable with the value `10.10.10.10,1.2.3.4` and restart all the services.

#### Advantages

- Follows current configuration patterns (Config file and Environment variables)
- Proxies can be added on a per node basis without a global list
- Does not require complex policy changes

#### Disadvantages

- Not centralized. Each node must be configured individually