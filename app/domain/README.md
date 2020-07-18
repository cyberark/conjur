## What is this folder?

- decouple from rails
- easily test
- common set of standards
- Make a coordinated business use case into an explicit, first-class object.
  - What does it coordinate?
    - Eg, Database query, audit, a log, and database update
- Link to Tim Riley talk

## CommandClass

- Jason convo:
  - Just a proc
  - Think of it like a configurable method
  - Could be instantiated in initializers
- Creates object under the hood.
  - Makes the parameters available as methods

- To undertand the motivation for the `CommandClass` gem, it's helpful to compare it
to how we'd do the same thing in vanilla ruby: 

Stage 1

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

Benefits: TODO

Visually, however, it's a bit noisy: we must manually pass the runtime
arguments of `call` down to every private method, creating clutter.

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

These costs aren't trivial, and even now I wonder if using the vanilla ruby
explicit argument-passing approach isn't better, all things considered, on a
large team full of developers with different levels of ruby experience.

I think the `CommandClass` code is cleaner once you're used to it, but more
difficult to understand before you are.  Which developers are we optimizing
for?  It's a point reasonable people can easily disagree on.

## Some Context

- DI Injection
- In theory, all of them could be created in an initializer
  - Instead, the function objects are recreated on each request
  - Doesn't matter from a performance perspective, but could give the wrong idea about what's happening
  - The call arguments should be considered just ordinary function arguments that come at runtime, typically through user input from a request.

## Value Objects vs Service Objects

- `Dry::Struct` is misused in a few places
- Prefer vanilla ruby objects
  - Verboseness > unfamiliar tools with a learning curve (link to golden rules)

## Pitfalls To Avoid

- Hardcoding dependencies that should be injected. (Rails.logger)
- Names that are too long or require additional comments to explain.
  - We want SimpleVerbPhrase names that match existing mental models.
  - PerformValidationChecks --> ValidateNewUser

## Design is still paramount

You can get the technique right, but still have create CommandClass's which are more difficult to understand and maintain than they could be.
This part is the art.
Too much in one.
Too little in one.
Splitting a `CommandClass` into two `CommandClass`'s before there is any need to. Instead, wait until you 
Functional logic in private methods that fits more naturally in a separate value object
