# Copyright (C) 2014 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'spec_helper'
require 'tempfile'

# RestClient monkey patches MIME::Types, breaking it in certain situations.
# Let's make sure we monkey patch the monkey patch if necessary.

describe RestClient::Request do
  shared_examples :restclient do
    it "can be initialized" do
      expect { RestClient::Request.new method: 'GET', url: 'http://example.com' }.to_not raise_error
    end
  end

  context 'default arguments' do
    let(:cache) { nil }
    let(:lazy) { false }
    it "sets cert_store to OpenSSL's default cert store" do
      request = RestClient::Request.new(method: 'GET', url: 'http://example.com')
      expect(request.ssl_opts[:cert_store]).to eq(OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE)
    end
  end
end
