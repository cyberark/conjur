# frozen_string_literal: true

namespace :"data-key" do
  desc "Create a data encryption key, which should be placed in the environment as CONJUR_DATA_KEY"
  task :generate do
    require 'slosilo'
    require 'base64'
    key = Base64.strict_encode64(Slosilo::Symmetric.new.random_key)
    print key
  end
end
