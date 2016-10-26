Before do
  @user_index = 0

  Role.dataset.delete
  Secret.dataset.delete
  Credentials.dataset.delete
  
  admin_role = Role.create(role_id: "cucumber:user:admin")
  Credentials.new(role: admin_role).save(raise_on_save_failure: true)
end

Before("@logged-in") do
  step %Q(I am a user named "alice")
end

Before("@logged-in-admin") do
  step %Q(I am the super-user)
end
