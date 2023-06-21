# Slosilo

Slosilo is providing a ruby interface to some cryptographic primitives:
- symmetric encryption,
- a mixin for easy encryption of object attributes,
- asymmetric encryption and signing,
- a keystore in a postgres sequel db -- it allows easy storage and retrieval of keys,
- a keystore in files.

## Installation

Add this line to your application's Gemfile:

    gem 'slosilo'

And then execute:

    $ bundle

## Compatibility

Version 3.0 introduced full transition to Ruby 3.
Consumers who use slosilo in Ruby 2 projects, shall use slosilo V2.X.X.

Version 2.0 introduced new symmetric encryption scheme using AES-256-GCM
for authenticated encryption. It allows you to provide AAD on all symmetric
encryption primitives. It's also **NOT COMPATIBLE** with CBC used in version <2.

This means you'll have to migrate all your existing data. There's no easy way to
do this currently provided; it's recommended to create a database migration and
put relevant code fragments in it directly. (This will also have the benefit of making
the migration self-contained.)

Since symmetric encryption is used in processing asymetrically encrypted messages,
this incompatibility extends to those too.

## Usage

### Symmetric encryption

```ruby
sym = Slosilo::Symmetric.new
key = sym.random_key
# additional authenticated data
message_id = "message 001"
ciphertext = sym.encrypt "secret message", key: key, aad: message_id
```

```ruby
sym = Slosilo::Symmetric.new
message = sym.decrypt ciphertext, key: key, aad: message_id
```

### Encryption mixin

```ruby
require 'slosilo'

class Foo
  attr_accessor :foo
  attr_encrypted :foo, aad: :id

  def raw_foo
    @foo
  end

  def id
    "unique record id"
  end
end

Slosilo::encryption_key = Slosilo::Symmetric.new.random_key

obj = Foo.new
obj.foo = "bar"
obj.raw_foo # => "\xC4\xEF\x87\xD3b\xEA\x12\xDF\xD0\xD4hk\xEDJ\v\x1Cr\xF2#\xA3\x11\xA4*k\xB7\x8F\x8F\xC2\xBD\xBB\xFF\xE3"
obj.foo # => "bar"
```

You can safely use it in ie. ActiveRecord::Base or Sequel::Model subclasses.

### Asymmetric encryption and signing

```ruby
private_key = Slosilo::Key.new
public_key = private_key.public
```

#### Key dumping
```ruby
k = public_key.to_s # => "-----BEGIN PUBLIC KEY----- ...
(Slosilo::Key.new k) == public_key # => true
```

#### Encryption

```ruby
encrypted = public_key.encrypt_message "eagle one sees many clouds"
# => "\xA3\x1A\xD2\xFC\xB0 ...

public_key.decrypt_message encrypted
# => OpenSSL::PKey::RSAError: private key needed.

private_key.decrypt_message encrypted
# => "eagle one sees many clouds"
```

#### Signing

```ruby
token = private_key.signed_token "missile launch not authorized"
# => {"data"=>"missile launch not authorized", "timestamp"=>"2014-10-13 12:41:25 UTC", "signature"=>"bSImk...DzV3o", "key"=>"455f7ac42d2d483f750b4c380761821d"}

public_key.token_valid? token # => true

token["data"] = "missile launch authorized"
public_key.token_valid? token # => false
```

### Keystore

```ruby
Slosilo::encryption_key = ENV['SLOSILO_KEY']
Slosilo.adapter = Slosilo::Adapters::FileAdapter.new "~/.keys"

Slosilo[:own] = Slosilo::Key.new
Slosilo[:their] = Slosilo::Key.new File.read("foo.pem")

msg = Slosilo[:their].encrypt_message 'bar'
p Slosilo[:own].signed_token msg
```

### Keystore in database

Add a migration to create the necessary table:

    require 'slosilo/adapters/sequel_adapter/migration'

Remember to migrate your database

    $ rake db:migrate

Then
```ruby
Slosilo.adapter = Slosilo::Adapters::SequelAdapter.new
```

## Contributing

We welcome contributions of all kinds to this repository. For instructions on
how to get started and descriptions of our development workflows, please see our
[contributing guide](CONTRIBUTING.md).
