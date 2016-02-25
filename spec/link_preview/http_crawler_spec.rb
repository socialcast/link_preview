# encoding: UTF-8

# Copyright (c) 2014-2016, VMware, Inc. All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'spec_helper'

describe LinkPreview::HTTPCrawler do
  let(:config) { LinkPreview::Configuration.new }

  let(:crawler) { LinkPreview::HTTPCrawler.new(config) }

  describe '#dequeue!' do
    before do
      crawler.enqueue!('http://example.com')
    end

    context 'when http_client.get raises an exception' do
      before do
        allow(config.http_client).to receive(:get).and_raise(Timeout::Error)
        expect(config.error_handler).to receive(:call).once { 'something' }
      end

      subject(:response) { crawler.dequeue! }

      it 'should receive error_handler call and return non successful response' do
        should be_a(Faraday::Response)
        should_not be_success
      end
    end
  end
end
