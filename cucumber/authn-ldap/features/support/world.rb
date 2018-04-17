module ConjurWorld
  def load_root_policy(policy)
    conjur_api.load_policy('root',
                           policy,
                           method: Conjur::API::POLICY_METHOD_PUT)
  end

  def invoke(status: nil, &block)
    @result = yield
    raise 'Expected invocation to be denied' if status && status != 200
    @result.tap do |result|
      puts result if @echo
    end
  rescue RestClient::Exception => e
    expect(e.http_code).to eq(status) if status
    @result = e.response.body
  end
end

World(ConjurWorld)
