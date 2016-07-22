Before do |scenario|
  @scenario_name = scenario.name
end

Before "@echo" do |scenario|
  @echo = true
end
