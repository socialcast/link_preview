# encoding: UTF-8
require 'spec_helper'

describe LinkPreview::HTTPCrawler do
  let(:config) { LinkPreview::Configuration.new }

  subject(:crawler) { LinkPreview::HTTPCrawler.new(config) }

  describe '#dequeue!' do
    before do
      crawler.enqueue!('http://example.com')
    end

    context 'when http_client.get raises an exception' do
      before do
        config.http_client.stub(:get).and_raise(Timeout::Error)
      end

      it 'should receive error_handler call' do
        config.error_handler.should_receive(:call).once
        crawler.dequeue!
      end
    end
  end
end

