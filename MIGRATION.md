# Migration

Migrating data from Conjur Open Source to a Conjur EE appliance is simple
using the provided export tools.

#### Creating a migration archive

To create the migration data archive:

1. Open a shell session in the Conjur Open Source container, for example:
    ```sh-session
    $ docker-compose exec conjur bash
    # OR
    $ docker exec -it conjur bash
    ```

2. Run the export command
    ```sh-session
    $ conjurctl export -o /var/export
    Exporting to '/var/export'...
    Generating key file /var/export/key
    gpg: directory `/root/.gnupg' created
    gpg: new configuration file `/root/.gnupg/gpg.conf' created
    gpg: WARNING: options in `/root/.gnupg/gpg.conf' are not yet active during this run
    gpg: keyring `/root/.gnupg/pubring.gpg' created

    Export placed in /var/export/2018-07-23T21-08-19Z.tar.xz.gpg
    It's encrypted with key in /var/export/key.
    If you're going to store the export, make
    sure to store the key file separately.
    ```

3. Copy the data archive and encryption key out of the container
    > NOTE: There will be two files in the export:
    > - A file called `key`, which contains the encryption key for the archive
    > - A timestamped file ending with `.tar.xz.gpg`. This is the exported Conjur
    >   data, protected by the key
    ```sh-session
    $ docker copy conjur:/var/export ./export
    ```

These files can now be used to migrate the data into a new Conjur EE appliance.