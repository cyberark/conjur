# Conjur Code Architecture <!-- omit in toc -->

- [Module Monolith](#module-monolith)
  - [Components](#components)
    - [Component Architecture](#component-architecture)

This design covers a proposed architecture for Conjur. Conjur is currently constructed primarily as a monolith. My monolith, I mean that for the majority of the code in Conjur, there is no visible separation between areas of responsibility. This approach is appropriate for a fast moving small team trying to identify value.  

Conjur has achieved an understanding of value delivery and now has multiple teams actively contributing to the code base. The value of the simple monolithic architecture no longer meets the need of our organization. To better support multiple teams contributing to the code base, I propose we move to a Modular Monolith.

## Module Monolith

A module monolith is one which separates real world business concepts into components within a single code base.  This approach joins the advantages of micro-services (distinct component interfaces), with the ease of development in a single repository.

![](https://cdn.shopify.com/s/files/1/0779/4361/files/MonolithvsMicroservicesbySimonBrown.jpg?v=1550774521)


## Components

A component is based on a real world concept. Components should include all functionality required to accomplish their business purpose. It is critical to note that components are not based around code level functionality. A good example of a component in Conjur is an authenticator.  The Azure authenticator includes all the functional bits required to perform its business function: *authenticate a resource using its Azure identity* within its namespace. External dependencies, like logging, are explicitly passed into each authenticator instead of referenced from inside the authenticator.

### Component Architecture

All components live within a `components` folder, located in the project root directory.

Components can take two forms: Ruby Gem, and [Rails Engine](https://guides.rubyonrails.org/engines.html). A Gem is a Ruby library which, when well written, simplifies interactions with a business function. An Engine is essentially a mini application. Just like a Gem, a well written Engine simplifies interactions with a business function, but it includes constructs like controllers and persistance.

Components are included in the larger monolith through with Bundler. Instead of referencing a remote gem, we reference a local Gem:

```ruby
# Gemfile.rb

gem 'authn-azure', path: 'components/authenticators/authn_azure'
```

The above example would add the Azure Authenticator Gem to the Conjur application.

### Component Guidelines

- Components should have standalone test suites configured as separate jobs within your CI platform.
- Components must be careful requiring dependencies. Generally, dependencies should be as loose as possible. Components with strict dependencies make upgrading dependencies in the monolith a pain.
- Components must not monkeypatch Ruby standard classes or other objects. This makes including the Components not have side effects on core Ruby classes.
- Cross-component associations are always violating componentization.
- Calls are ok only to component elements that are explicitly made public.$$

