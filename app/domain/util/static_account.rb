module StaticAccount
  def self.account
    @account ||= "conjur"
    @account
  end

  def self.set_account(account)
    @account = account
  end
end