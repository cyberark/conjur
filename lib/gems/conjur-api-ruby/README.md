# Conjur::API

Programmatic Ruby access to the Conjur API.

# Server Versions

The Conjur server comes in two major versions:

* **4.x** Conjur 4 is a commercial, non-open-source product, which is documented at [https://developer.conjur.net/](https://developer.conjur.net/).
* **5.x** Conjur 5 is open-source software, hosted and documented at [https://www.conjur.org/](https://www.conjur.org/). 

You can use the `master` branch of this project, which is `conjur-api` version `5.x`, to do all of the following things against either type of Conjur server:

* Authenticate
* Fetch secrets
* Check permissions
* List roles, resources, members, memberships and permitted roles.
* Create hosts using host factory
* Rotate API keys

Use the configuration setting `Conjur.configuration.version` to select your server version, or set the environment variable `CONJUR_VERSION`. In either case, the valid values are `4` and `5`; the default is `5`.

If you are using Conjur server version `4.x`, you can also choose to use the `conjur-api` version `4.x`. In this case, the `Configuration.version` setting is not required (actually, it doesn't exist).

# Installation

Add this line to your application's Gemfile:

    gem 'conjur-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install conjur-api

# Usage

Connecting to Conjur is a two-step process:

* **Configuration** Instruct the API where to find the Conjur endpoint and how to secure the connection.
* **Authentication** Provide the API with credentials that it can use to authenticate.

## Configuration

The simplest way to configure the Conjur API is to use the configuration file stored on the machine.
If you have configured the machine with [conjur init](http://developer.conjur.net/reference/tools/init.html),
it's default location is `~/.conjurrc`. 

The Conjur configuration process also checks `/etc/conjur.conf` for global settings. This is typically used
in server environments.

For custom scenarios, the location of the file can be overridden using the `CONJURRC` environment variable. 

You can load the Conjur configuration file using the following Ruby code:

```ruby
require 'conjur/cli'
Conjur::Config.load
Conjur::Config.apply
```

**Note** this code requires the [conjur-cli](https://github.com/conjurinc/cli-ruby) gem, which should also be in your
gemset or bundle.

## Authentication

Once Conjur is configured, the connection can be established like this:

```
conjur = Conjur::Authn.connect nil, noask: true
```

To [authenticate](http://developer.conjur.net/reference/services/authentication/authenticate.html), the API client must
provide a `login` name and `api_key`. The `Conjur::Authn.connect` will attempt the following, in order:

1. Look for `login` in environment variable `CONJUR_AUTHN_LOGIN`, and `api_key` in `CONJUR_AUTHN_API_KEY` 
2. Look for credentials on disk. The default credentials file is `~/.netrc`. The location of the credentials file
can be overridden using the configuration file `netrc_path` option. 
3. Prompt for credentials. This can be disabled using the option `noask: true`.

## Connecting Without Files

It's possible to configure and authenticate the Conjur connection without using any files, and without requiring
the `conjur-cli` gem.

To accomplish this, apply the configuration settings directly to the [Conjur::Configuration](https://github.com/conjurinc/api-ruby/blob/master/lib/conjur/configuration.rb) 
object.

For example, specify the `account` and `appliance_url` (both of which are required) like this:

```
Conjur.configuration.account = 'my-account'
Conjur.configuration.appliance_url = 'https://conjur.mydomain.com/api'
```

You can also specify these values using environment variables, which is often a bit more convenient. 
Environment variables are mapped to configuration variables by prepending `CONJUR_` to the all-caps name of the 
configuration variable. For example, `appliance_url` is `CONJUR_APPLIANCE_URL`, `account` is `CONJUR_ACCOUNT`.

In either case, you will also need to configure certificate trust. For example:

```
OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.add_file "/etc/conjur-yourorg.pem"
```

Once Conjur is configured, you can create a new API client by providing a `login` and `api_key`:

```
Conjur::API.new_from_key login, api_key
```

Note that if you are connecting as a [Host](http://developer.conjur.net/reference/services/directory/host), the login should be 
prefixed with `host/`. For example: `host/myhost.example.com`, not just `myhost.example.com`.

# Development

The file `docker-compose.yml` is a self-contained development environment for the project.

## Starting

To bring it up, run:

```sh-session
$ docker-compose build
$ docker-compose up -d pg conjur_4 conjur_5
```

Then configure the v4 and v5 servers:

```sh-session
$ ./ci/configure_v4.sh
...
$ ./ci/configure_v5.sh
...
```

## Using

Obtain the API key for the v5 admin user:

```
$ docker-compose exec conjur_5 rake 'role:retrieve-key[cucumber:user:admin]'
3aezp05q3wkem3hmegymwzz8wh3bs3dr6xx3y3m2q41k5ymebkc
```

The password of the v4 admin user is "secret".

Now you can run the client `dev` container:

```sh-session
$ docker-compose run --rm dev
```

This gives you a shell session with `conjur_4` and `conjur_5` available as linked containers.

## Demos

For a v5 demo, run:

```sh-session
$ bundle exec ./example/demo_v5.rb <admin-api-key>
```

For a v4 demo, run:

```sh-session
$ bundle exec ./example/demo_v4.rb
```

## Stopping

To bring it down, run:

```sh-session
$ docker-compose down
```

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# License

Copyright 2016-2017 CyberArk

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this software except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
