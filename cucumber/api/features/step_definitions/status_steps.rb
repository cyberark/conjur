Then(/^the html result contains current possum version$/) do
  value = File.read(File.expand_path("../../../../VERSION_APPLIANCE", File.dirname(__FILE__)))
  step "the html result contains \"Version #{value}\""
end
