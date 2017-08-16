---
title: Install Conjur CLI
layout: page
section: get-started
---

{% include toc.md key='get' %}

{% include toc.md key='get' section='docker' %}

You can easily download and run the Conjur CLI using the official pre-built images hosted by Docker Hub.

If you run the container with interactive mode (`-it`), then you will get an interactive `bash` shell. Otherwise, you will run a single `conjur` command.

Here's how to run the CLI interactively:

{% highlight shell %}
$ docker run --rm \
    -it \
    -v $PWD:/work
    conjurinc/cli5
root@5628127eac77:/# cd work
root@5628127eac77:/work# which conjur
/usr/local/bundle/bin/conjur
{% endhighlight %}

And here's how to run a single Conjur command (without arguments, it prints the help string):

{% highlight shell %}
$ docker run --rm \
    -e CONJUR_APPLIANCE_URL=http://conjur \
    -e CONJUR_ACCOUNT=myorg \
    -e CONJUR_AUTHN_LOGIN=admin \
    -e CONJUR_AUTHN_API_KEY=the-secret-api-key \   
    conjurinc/cli5
NAME
    conjur - Command-line toolkit for managing roles, resources and privileges
...
{% endhighlight %}

{% include toc.md key='get' section='source' %}

You can also build and run the CLI from source.

Start by cloning the `possum` branch of [https://github.com/conjurinc/cli-ruby](https://github.com/conjurinc/cli-ruby).

Then run `bundle`, and `bundle exec ./bin/conjur`.

{% include toc.md key='configure' %}

The Conjur command-line interface requires two settings to connect to the server. You can configure these two settings along with some optional ones using either the environment or using files.

{% include toc.md key='configure' section='environment' %}

To configure using the environment, export the following variables:

* **CONJUR_APPLIANCE_URL** The URL to the Conjur server (example: "http://conjur")
* **CONJUR_ACCOUNT** The organization account name (example: "mycorp").

If your Conjur server is using a self-signed certificate, you can establish SSL trust to Conjur with one of the following:

* **CONJUR_SSL_CERTIFICATE** The SSL certificate.
* **CONJUR_CERT_FILE** The path to the certificate file on disk.

<div class="note">
<strong>Note</strong> Certificate configuration is not required if you are running Conjur in dev mode without HTTPS, or if you are running Conjur with HTTPS and the certificate is already trusted by your operating system.
</div>
<p/>

You can configure a shell session for the CLI by exporting the variables shown above. For example:

{% highlight shell %}
$ export CONJUR_APPLIANCE_URL=http://conjur
$ export CONJUR_ACCOUNT=mycorp
$ conjur authn login admin
Please enter admin's password (it will not be echoed): *******
Logged in
{% endhighlight %}

{% include toc.md key='configure' section='conjur-init' %}

You can use the command `conjur init` to automatically configure the connection settings and save them to configuration files which will persist across sessions. This is especially useful with certificates because it will fetch the server certificate and show you how to verify its fingerprint.

Here's an example:

{% highlight shell %}
$ conjur init
Enter the URL of your Conjur service: https://conjur

SHA1 Fingerprint=08:3B:71:72:02:43:6E:CA:ED:42:86:93:BA:7E:DF:81:C4:BC:62:30

Please verify this certificate on the appliance using command:
    openssl x509 -fingerprint -noout -in ~conjur/etc/ssl/conjur.pem
Trust this certificate (yes/no): yes
Enter your organization account name: mycorp
Wrote certificate to /root/conjur-mycorp.pem
Wrote configuration to /root/.conjurrc
{% endhighlight %}

Two configuration files are saved to your home directory:

* **$HOME/conjur-$account.pem** The server certificate.
* **$HOME/.conjurrc** A YAML file containing configuration settings.

Here's an example of `$HOME/.conjurrc`:

{% highlight yaml %}
account: mycorp
appliance_url: https://conjur
cert_file: "/root/conjur-mycorp.pem"
{% endhighlight %}

You can create these files yourself without assistance from `conjur init` once you have obtained them once.

You can also change the location where the CLI looks for the `.conjurrc` file by setting the environment variable `$CONJURRC`. For example, to configure the CLI to find the config file in `/etc/`:

{% highlight shell %}
$ export CONJURRC=/etc/conjur.conf
{% endhighlight %}

This is the recommended location when the Conjur configuration is installed system-wide. Note that neither the Conjur configuration nor the server SSL certificate are secret data. They can be safely distributed in the following ways:

* Committed to source control.
* Distributed through configuration management.
* Baked into VM and container images.

{% include toc.md key='login' %}

Once you've downloaded the client, you'll login to Conjur. If you started
the server yourself, you'll need the `admin` API key or password. If
someone else is managing the Conjur server, they will provide you with
your login information.

{% highlight shell %}
$ conjur authn login
Enter your username to log into Conjur: admin
Enter password for user admin (it will not be echoed):
Logged in
{% endhighlight %}

You can show your current logged-in user with `conjur authn whoami`:

{% highlight shell %}
$ conjur authn whoami
{"account":"mycorp","username":"admin"}
{% endhighlight %}
