class WSWorld
  include RSpec::Expectations
  include RSpec::Matchers
end

World do
  WSWorld.new
end
