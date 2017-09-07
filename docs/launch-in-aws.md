---
title: Launch CyberArk Conjur In The Cloud
layout: page
section: get-started
---

You can easily launch a private, production-ready Conjur server in the
cloud using Conjur's official template for Amazon CloudFormation.

## Prerequisites

First, you'll need an Amazon Web Services account. If you already have
one, skip ahead. If not, you can [create a free account
here][aws-signup].

Then you need to [download the Conjur CloudFormation
template][cf-template]. It's a plain text file that instructs AWS how
to create the Conjur stack. You'll need this for the next step.

## Prepare to launch

1. Sign-in to your Amazon Web Services dashboard and notice the search
   bar directly under the "AWS Services" heaer. Search for
   "CloudFormation" and hit <kdb>Enter</kbd> to navigate.
1. Choose the blue button labeled "Create new stack".
1. Under "Select Template" and "Choose a template", choose "Upload a
   template to Amazon S3" and select the Conjur CloudFormation
   template file you downloaded.
1. Press the blue "Next" button in the lower-right corner.

## Launch the stack

Now use your browser to customize your Conjur stack in CloudFormation. 


1. Choose a stack name. If your organization were called `mycorp`, you
   might choose `mycorp-conjur`.
1. Choose an account name. You can have as many Conjur accounts as you
   want, but for most uses one is plenty, and the name you choose here
   will be available as soon as you create the stack. For example, you
   might call the account `mycorp`.
1. Choose an admin password for the Conjur account and for the database.

   <div class="alert alert-info" role="alert"><strong>Prevent data loss:</strong><br>
     When you launch the stack, you must supply an admin password for
     the Conjur account and a database. Back them up in a safe location.
   </div>
1. Specify the location of the Amazon Machine Image to use for Conjur.
   TODO: what should we suggest for this?
1. Specify the name of the AWS key pair to use.
   TODO: what is this and what should we suggest?
1. Choose a VPC ID in which to launch your stack.
   TODO: what is this and what should we suggest?
1. Specify two VPC subnets to use for your stack.
   TODO: what is this and what should we suggest?
1. Choose the Amazon machine type to use for your instance.
   > "`t2.medium` ought to be enough for anybody."
   > -Ryan Prior
1. Press the blue "Next" button in the lower-right corner.

## Connect

First, check to see that your server is running. Visit
`https://your-server-ip/` in your browser, substituting the IP address
of your server. This tells you the server is running but doesn't let
you log in or access any data.

The easiest way to do that is using the official Conjur client Docker
container.

1. [Install Docker Toolbox][get-docker], available for Windows and macOS.

   If you're using GNU/Linux, [follow instructions here][get-docker-gnu].

1. Install a terminal application if you don't have one already.
   [Hyper](https://hyper.is) is nice.

1. In your terminal, download & run the Conjur client:

   ```sh-session
   $ docker run --rm -it -v $PWD:/work -w /work conjurinc/cli5
   ```

1. Initialize the Conjur client using your server IP address with the
   account name and admin password you created:
   
   ```sh-session
   $ conjur init -u https://your-server-ip -a your-account-name
   $ conjur authn login -u admin
   Please enter admin's password (it will not be echoed):
   ```
   
   Remember to substitute your server's IP address and the name of the
   account.

## Explore

You are connected and ready to use Conjur! Ready to do more? Here are
some suggestions:

```sh-session
$ conjur authn whoami
$ conjur help
$ conjur help policy load
```

* Go through the [Conjur Tutorials](/tutorials/)
* View Conjur's [API Documentation](/api.html)

[aws-signup]: https://aws.amazon.com/what-is-aws/
[cf-template]: https://raw.githubusercontent.com/cyberark/conjur/master/aws/cloudformation/conjur.yml
[get-docker]: https://www.docker.com/products/docker-toolbox
[get-docker-gnu]: install-docker-on-gnu-linux.html

