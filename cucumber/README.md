# Conjur Cucumber Tests

## Tag Descriptions

- Feature Area (`@api`, `@authenticators_azure`, etc.)

    These tags are added to each feature file and correspond to the feature
    sub-directory name.

- `@smoke`

    Indicates a "happy-path" test for a given feature in its simplest form.

- `@acceptance`

    Tests for a feature that verify its acceptance criteria. These include
    edge cases, unique data, etc..

- `@negative`

    A negative scenario is where invalid data/values/behavior are entered to
    generate an error condition.

    Example: entering a bad username and password should result in error/401
    unauthorized status

    Note: For negative AC - these should still be tagged as negative but also
    be included as part of acceptance tests

- `@performance`

    Indicates a time-based measurement test to verify feature performance.
