class LdapLog
	def instrument(event, payload, &block)
		block.call(payload).tap do
      puts 'Logging...'
			$stderr.puts "[ldap: #{event}] #{clean_payload(payload).inspect}}"
		end
	end

	private
	def clean_payload payload
		if payload[:connection].kind_of?(Net::LDAP::Connection)
			payload[:connection] = "<connection>"
		end
		if payload[:syntax]
			payload[:syntax] = "<syntax>"
		end
		payload
	end
end
