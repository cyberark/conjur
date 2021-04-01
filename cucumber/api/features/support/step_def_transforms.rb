# frozen_string_literal: true

# See:
#   https://github.com/cucumber/cucumber/wiki/Step-Argument-Transforms
# for an explanation of this cucumber feature.
#
# Replaces:
#   @response_api_key@ with the actual @response_api_key
ParameterType(
  name: 'response_api_key',
  regexp: /@response_api_key@/,
  prefer_for_regexp_match: true,
  transformer: lambda do |item|
    @response_api_key ? item.gsub("@response_api_key@", @response_api_key) : item
  end
)

# Replaces:
#   @host_factory_token_expiration@ with an actual expiration time
#   @host_factory_token_token@ with an actual token
#
DummyToken = Struct.new(:token, :expiration)

def render_hf_token(tmpl)
  token = @result.dig(0, 'token')
  return tmpl unless token

  tmpl.gsub("@host_factory_token@", token)
end

def render_hf_token_expiration(tmpl)
  exp = @result.dig(0, 'expiration')
  return tmpl unless exp

  tmpl.gsub("@host_factory_token_expiration@", parse_expiration(exp))
end

def parse_expiration(exp)
  Time.parse(exp).utc.iso8601
end

def render_hf_token_and_expiration(tmpl)
  render_hf_token_expiration(render_hf_token(tmpl))
end

ParameterType(
  name: 'host_factory_token',
  regexp: /@host_factory_token@/,
  transformer: lambda do |item|
    # TODO: This coupling to global state is terrible, but seems to be
    #       unvoidable using the cucumber World approach.
    # TODO: replace these bodies with functions above
    token = @host_factory_token || DummyToken.new(
      @result[0]['token'], parse_expiration(@result[0]['expiration'])
    )
    
    item.gsub("@host_factory_token@", token.token)
  end
)

ParameterType(
  name: 'host_factory_token_expiration',
  regexp: /@host_factory_token_expiration@/,
  transformer: lambda do |item|
    # TODO: This coupling to global state is terrible, but seems to be
    #       unvoidable using the cucumber World approach.
    token = @host_factory_token || DummyToken.new(
      @result[0]['token'], parse_expiration(@result[0]['expiration'])
    )
    
    item.gsub("@host_factory_token_expiration@", token.expiration)
  end
)
