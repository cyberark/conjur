#!/usr/bin/env ruby

require 'ladle'

ladle = Ladle::Server.new(port: 389,
	ldif: '/etc/ldap.ldif',
	domain: 'dc=conjur,dc=net'
)
ladle.start

while true
	sleep 1
end