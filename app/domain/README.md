# Why `app/domain`?

## Introduction

This document explains the coding standards used in `app/domain`, and the
motivation behind them.  By design, these standards are differerent from those
of a typical Rails app. 

You can think of `app/domain` as a haven where pure Conjur business logic (the
Conjur "domain") lives as plain ruby code, unpolluted by framework-specific
concepts like controllers or routes.  The code in this folder should have no
dependencies on Rails itself (if you find any, they are likely mistakes we
should fix).  

Currently, `app/domain` contains mostly authentication logic.  But its scope is
not limited to authenticators.

At the highest level, this approach aims for:

- Explicit, maintainable code that is easy to understand
- Fast unit tests
- Intuitive names that correspond with our documentation and the way we
  naturally talk

We'll dig into the technical specifics below.

## The "Functional Object-Oriented" Style

I'll offer a TLDR version here.  For more in depth discussion of the same
principles, the video [Functional Architecture for the Practical
Rubyist](https://www.youtube.com/watch?v=7qnsRejCyEQ&feature=youtu.be) is a
good place to start.

The basic idea is to reap many benefits of functional programming while 
remaining true to ruby's objected-oriented paradigm.

In brief, this means building features out of three basic kinds of objects, and
maintaing a strict sepration of responsibilities:

- **Command objects**
  - These go by many names: service objects, interactors, use cases
  - Coordinates high-level logic involving multiple collaborators
    - For example: `CreateUser` might need to coordinate user input validation,
      a database transaction, a log entry, and a confirmation email
  - Makes all collaborators explicit as dependencies
  - Easy to unit test with doubles or mocks
- **Value objects**
  - These are essentially data types.
  - Methods return data the object was initialized with, or transformations of
    it
  - For example: `User`, `Address`, `Url`, etc.
  - Immutable
  - No side effects
  - Class names are nouns
  - Method names are nouns describing what they return
- **Objects with side effects**
  - Repositories for performing database transactions
  - Objects that communicate with network services (`Aws`, `Github`, etc)
  - Objects that interact with the file system
  - Class names are usually nouns
  - Method names are verbs (to emphasize their side-effects)
    - For example: `github.fetch_issues`
    - By contrast, a value object would use a name like `github.issues`.  The
      "fetch" indicates the network side effect and possibility of error.

Other principles include:

- Avoid inheritance
  - Instead, make shared code into its own object, which is passed into other
    objects that need it.  Composition over inheritance.
- All objects are immutable
- Careful, consistent naming practices that align with documentation

### Specific Technologies

Writing in the functional OO style does not require any specific gems, though
many gems make it easier to write value objects and command objects.

In general, there is a tradeoff when using gems:

- Positive: 
  - They cut down on boilerplate and make your code more concise
- Negative: 
  - Every new developer has another extra thing to learn
  - The code is often not as obvious as plain ruby

You'll encounter two gems when working in Conjur:

- `command_class` for writing command objects
  - This is still used extensively.  Read below for more information.
- `dry-struct` for value objects
  - While this is a good gem, I've stopped using inside Conjur for the reasons
    listed above
  - I now write value objects using plain ruby

## `CommandClass` Deep Dive

The [`command_class` README](https://github.com/jonahx/command_class) has basic
information about usage.  Here I'll note points of confusion and design
considerations.

### Dependencies vs Inputs

Remember that an instance of a `CommandClass` is just a ruby proc, as
is anything with a `call` method.  Roughly, then, you can think of a proc as a
function.  So a `CommandClass` is really just a _configurable function_, and an
instance is a _configured function_.

How is it configured?  With its dependencies.

The _inputs_, by contrast, are the _configured function's arguments_.  They're
what you pass when you call the "function".

Another way to think of this is that dependencies are known when the program
starts: Your entire program, even a multi-threaded one, needs only a single
instance of each `CommandClass` it uses.  In Conjur, we often create
`CommandClass` instances in controllers on each request. This avoids dealing
with Rails initializers, but conceptually speaking it's an abuse of the
pattern, even though it doesn't matter much practically.

The inputs, on the other hand, are known only at runtime. They're often, but
not necessarily, given as the params of an http request.  

### Pitfalls To Avoid

- Hardcoding dependencies that should be injected.
  - For example: Directly referencing `Rails.logger` or a model class.
  - All code with side effects should be injected as a depenency.
- Names that are too long or require additional comments to explain.
  - Too verbose: `PerformValidationChecks`.  Better:  `ValidateNewUser`

### Design is still paramount

Explicit dependencies help you write code that's easy to test and read, but
they don't guarantee it.  It's still possible to write confusing or complex
code using these patterns.  There is still some art to good design that's hard
to capture.  Nothing beats a set of fresh, critical eyes to validate
readability.

A few heuristics to keep in mind:

- Avoid putting too many responsibilities into a command class.  Its single
  verb phrase name should naturally describe it.
  - Split up a `CommandClass` when needed
- Avoid putting too little in one.  Not everything should be a `CommandClass`.
  Keep in mind why we write them.
  - Avoid splitting up a `CommandClass` prematurely.  Wait until there's a need
    to.

### `CommandClass` in Plain Ruby

To undertand the motivation for the `CommandClass` gem, it's helpful to see
how we'd do the same thing in vanilla ruby: 

```ruby
class DoSomeUseCase
  def initialize(dependency1: dep1, dependency2: dep2)
    @dependency1 = dep1
    @dependency2 = dep2
  end

  def call(arg1, arg2)
    do_action1(arg1, arg2)
    do_action2(arg1)
  end

  private

  def do_action1(arg1, arg2)
    do_sub_action1(arg1, arg2)
    do_sub_action2(arg1, arg2)
  end

  def do_sub_action1(arg1, arg2)
    @dependency1.something(arg1)
    @dependency2.something(arg2)
  end

  def do_sub_action2(arg1, arg2)
    @dependency2.something(arg2)
  end

  def do_action2(arg1)
    # something here
  end
end
```

This is a perfectly legitimate, vanilla ruby alternative to the `CommandClass`,
with all the same high-level benefits.  

Visually, however, it's a bit noisy: we manually pass the runtime arguments of
`call` down to every private method, creating clutter.

Our first instinct might be to save the arguments as member variables, giving
all methods access to them.  But if we did something like:

```ruby
def call(arg1, arg2)
  @arg1 = arg1
  @arg2 = arg2
  do_action1
  do_action2
end
```

Then our `call` method would no longer be thread safe.  Remember a single
instance of `DoSomeUseCase` should be able to serve multiple requests
simultaneously.

So if we want to avoid argument passing, we must introduce a separate object
that has _both_ the runtime arguments and the original dependencies as
attributes, and create a new instance of _that_ object every time
`DoSomeUseCase#call` is invoked:

```ruby
class DoSomeUseCase

  class Run
    def initialize(dep1, dep2, arg1, arg2)
      @dep1 = dep1
      @dep2 = dep2

      @arg1 = arg1
      @arg2 = arg2
    end

    def call
      do_action1
      do_action2
    end

    private

    def do_action1
      do_sub_action1
      do_sub_action2
    end

    def do_sub_action1
      @dep1.something(@arg1)
      @dep2.something(@arg2)
    end

    def do_sub_action2
      @dep2.something(@arg2)
    end

    def do_action2
      # something here
    end
  end

  def initialize(dependency1: dep1, dependency2: dep2)
    @dependency1 = dep1
    @dependency2 = dep2
  end

  def call(arg1, arg2)
    Run.new(dependency1, dependency2, arg1, arg2).call
  end
end
```

We've eliminated the argument-passing clutter and we're still thread safe.
_But_ the price is boilerplate and complexity: An additional nested class to
write and keep track of, and the duplication of the dependencies as attributes
in both `DoSomeUseCase` and the nested `Run` class.

So we now have two options for vanilla ruby alternatives to the `CommandClass`:

1. One which is coneptually simple but cluttered by passing runtime arguments
   between all the methods.
1. One which avoids that clutter but at the expense of other complexity and
   boilerplate.

The `CommandClass` is simply a third option, which takes the second approach --
creating a new `Run` object instance every time `call` is invoked -- but
magically performs the boilerplate for you using meta-programming.  That way,
you get the benefits of uncluttered code without having to pay the price of
writing boilerplate.

### Tradoffs

Of course, the `CommandClass` has its own price -- the price of magical code.
Its interface is not idiomatic ruby.  It has a bit of a learning curve.  And
how it works isn't obvious, even if you're experienced with ruby. 

These costs aren't trivial, and even now I sometimes wonder if using the
vanilla ruby explicit argument-passing approach isn't better, all things
considered, on a large team full of developers with different levels of ruby
experience.

I think the `CommandClass` code is cleaner once you're used to it, but more
difficult to understand before you are.  Which developers are we optimizing
for?  It's a debatable point.
