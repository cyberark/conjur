desc "Create a data encryption key, which should be placed in the environment as POSSUM_DATA_KEY"
task :"generate-data-key" do
  require 'slosilo'
  require 'base64'
  key = Base64.strict_encode64(Slosilo::Symmetric.new.random_key)
  puts key
end
