# frozen_string_literal: true

shared_context "fetch secrets" do

  let (:test_fetch_secrets_error) { "test-fetch-secrets-error" }

  def mock_fetch_secrets(is_successful:, fetched_secrets:)
    double('fetch_secrets').tap do |fetch_secrets|
      if is_successful
        allow(fetch_secrets).to receive(:call)
                                  .and_return(fetched_secrets)
      else
        allow(fetch_secrets).to receive(:call)
                                  .and_raise(test_fetch_secrets_error)
      end
    end
  end
end
