module Conjur

  # A Conjur Layer is a type of role whose members are Conjur Hosts. The hosts inherit
  # permissions from the layer. Automatic roles on the layer can also be used to manage
  # SSH permissions to the hosts.
  class Layer < BaseObject
    include ActsAsRolsource
  end
end
