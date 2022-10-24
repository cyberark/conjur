# frozen_string_literal: true

require_relative './test_extension_a'
require_relative './test_extension_b'
require_relative './test_extension_c'
require_relative './test_extension_d'
require_relative './test_extension_e'
require_relative './test_extension_f'

# To ensure we're not calling any outside code we don't expect, all extension
# code must be explicitly declared up front.
#
# Because we're referencing the classname before it is actually loaded
Conjur::Extension::Repository.register_extension(
  extension_kind: :rspec,
  extension_class: TestExtensionA
)

Conjur::Extension::Repository.register_extension(
  extension_kind: :rspec,
  extension_class: TestExtensionB
)

Conjur::Extension::Repository.register_extension(
  extension_kind: :rspec,
  extension_class: TestExtensionC
)

Conjur::Extension::Repository.register_extension(
  extension_kind: :rspec,
  extension_class: TestExtensionD
)

Conjur::Extension::Repository.register_extension(
  extension_kind: :rspec,
  extension_class: TestExtensionE
)

Conjur::Extension::Repository.register_extension(
  extension_kind: :rspec,
  extension_class: TestExtensionF
)
