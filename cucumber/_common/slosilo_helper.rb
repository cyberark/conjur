
def token_id(account, role, tag = "current")
  "authn:#{account}:#{role}:#{tag}"
end

def init_slosilo_keys
  slosilo_ids = [token_id("rspec", "host"), token_id("rspec", "user"), token_id("cucumber", "host"), token_id("cucumber", "user"),
                 token_id("cucumber", "user", "previous"),token_id("cucumber", "host", "previous")  ]
  Slosilo.each do |k, v|
    unless slosilo_ids.member?(k)
      Slosilo.send(:keystore).adapter.model[k].delete
    end
  end
end