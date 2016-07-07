Sequel.migration do
  change do
    create_table :roles do
      String :role_id, primary_key: true
      Integer :uidnumber
      Integer :gidnumber
      
      index [:uidnumber], unique: true
      index [:gidnumber], unique: true
    end
  end
end
