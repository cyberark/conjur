After do
  %w(LDAP_BASE LDAP_FILTER LOG_LEVEL).each do |key|
    ENV.delete key
  end
end
