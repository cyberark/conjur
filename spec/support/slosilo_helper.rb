# frozen_string_literal: true

def token_key(account, role, tag = "current")
  Slosilo[token_id(account, role, tag)]
end

def token_id(account, role, tag = "current")
  "authn:#{account}:#{role}:#{tag}"
end

def init_slosilo_keys(account)
  Slosilo[token_id(account, "host")] ||= Slosilo::Key.new
  Slosilo[token_id(account, "user")] ||= Slosilo::Key.new
end
