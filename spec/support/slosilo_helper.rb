# frozen_string_literal: true

def token_key(account, role)
  Slosilo[token_id(account, role)]
end

def token_id(account, role)
  "authn:#{account}:#{role}:current"
end

def init_slosilo_keys(account)
  Slosilo[token_id(account, "host")] ||= Slosilo::Key.new
  Slosilo[token_id(account, "user")] ||= Slosilo::Key.new
end

def init_slosilo_key_static_value(account,value)
  Slosilo[token_id(account, "user")] ||= Slosilo::Key.new(value)
end