# ConjurAudit

Conjur audit is a Rails engine that adds support to Conjur for storing and queryhing
audit records in a PostgreSQL database.

## Developing

To start a development environment that includes and enables Conjur audit:

1. Navigate to the development environment directory from the project root
    ```sh-session
    cd dev
    ```

2. Start the development environment with the audit flag
    ```sh-session
    ./start --audit
    ```

## Testing

To run the audit RSpec tests:

1. Start the development environment as described in the previous section.

2. Open a CLI session in the development environment
    ```sh-session
    ./cli exec
    ```
3. Run the rspec tests from the engine directory
    ```sh-session
    pushd engines/conjur_audit
    rake
    popd
    ```
