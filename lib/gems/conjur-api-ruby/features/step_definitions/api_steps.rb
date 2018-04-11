When(/^I(?: can)? run the code:$/) do |code|
  @result = eval(code).tap do |result|
    if ENV['DEBUG']
      puts result
    end
  end
end
