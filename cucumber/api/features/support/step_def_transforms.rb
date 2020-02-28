# frozen_string_literal: true

# See:
#   https://github.com/cucumber/cucumber/wiki/Step-Argument-Transforms
# for an explanation of this cucumber feature.
#
# TODO: Transform is now deprecated.  We should rewrite these as ParameterTypes:
#     https://cucumber.io/blog/2017/09/21/upgrading-to-cucumber-3

# Replaces:
#   @response_api_key@ with the actual @response_api_key
#
# Transform(/@response_api_key@/) do |item|
#   @response_api_key ? item.gsub("@response_api_key@", @response_api_key) : item
# end

ParameterType(
  name: 'response_api_key',
  regexp: /@response_api_key@/,
  transformer: ->(item) do
    @response_api_key ? item.gsub("@response_api_key@", @response_api_key) : item
  end
)

# Replaces:
#   @host_factory_token_expiration@ with an actual expiration time
#   @host_factory_token_token@ with an actual token
#
DummyToken = Struct.new(:token, :expiration)

# Transform(/@host_factory.+@/) do |item|
#   token = @host_factory_token || DummyToken.new(
#     @result[0]['token'], Time.parse(@result[0]['expiration'])
#   )
  
#   item.gsub("@host_factory_token_expiration@", token.expiration.utc.iso8601)
#       .gsub("@host_factory_token_token@", token.token)
# end

ParameterType(
  name: 'host_factory',
  regexp: /@host_factory.+@/,
  transformer: ->(item) do
    # TODO: This coupling to global state is terrible, but seems to be
    #       unvoidable using the cucumber World approach.
    token = @host_factory_token || DummyToken.new(
      @result[0]['token'], Time.parse(@result[0]['expiration'])
    )
    
    item.gsub("@host_factory_token_expiration@", token.expiration.utc.iso8601)
        .gsub("@host_factory_token_token@", token.token)
  end
)
