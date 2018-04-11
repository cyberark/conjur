# Helpers for REST client tests
module RequestHelpers
  def expect_request details, &block
    expect(RestClient::Request).to receive(:execute).with(hash_including(details), &block)
  end

  def allow_request details, &block
    allow(RestClient::Request).to receive(:execute).with(hash_including(details), &block)
  end
end
