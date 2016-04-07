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

describe LinkPreview::Parser do
  describe '#parse' do
    let(:config) { double(LinkPreview::Configuration) }
    let(:parser) { LinkPreview::Parser.new(config) }
    let(:response) do
      Faraday::Response.new.tap do |response|
        allow(response).to receive(:headers).and_return(headers)
        allow(response).to receive(:url).and_return(url)
        allow(response).to receive(:body).and_return(body)
      end
    end

    subject(:data) { parser.parse(response) }

    shared_examples 'oembed' do
      context 'when empty string' do
        let(:content) { '' }
        it { expect(data).to be_empty }
      end

      context 'when empty hash' do
        let(:content) { {} }
        it { expect(data).to be_empty }
      end

      context 'when invalid' do
        let(:content) { { 'version' => '1.0' } }
        it { expect(data).to be_empty }
      end

      context 'when valid link' do
        let(:content) { { 'version' => '1.0', 'type' => 'link' } }
        it { expect(data[:oembed]).to include(content) }
      end

      context 'when valid photo' do
        let(:content) { { 'version' => '1.0', 'type' => 'photo', 'url' => 'http://example.com/image.jpg' } }
        it { expect(data[:oembed]).to include(content) }
      end

      context 'when valid video' do
        let(:content) { { 'version' => '1.0', 'type' => 'video', 'url' => 'http://example.com/videos/1.mp4', 'html' => '<video src="http://example.com/videos/1.mp4"></video>' } }
        it { expect(data[:oembed]).to include(content) }
      end

      context 'when valid rich' do
        let(:content) { { 'version' => '1.0', 'type' => 'rich', 'url' => 'http://example.com/widget/1', 'html' => '<iframe></iframe>' } }
        it { expect(data[:oembed]).to include(content) }
      end
    end

    context 'with json oembed response' do
      let(:headers) { { content_type: 'application/json' } }
      let(:url) { 'http://example.com/oembed?url=http%3A%2F%2Fexample.com&format=json' }

      let(:body) do
        JSON.dump(content)
      end

      include_examples 'oembed'
    end

    context 'with xml oembed response' do
      let(:headers) { { content_type: 'text/xml' } }
      let(:url) { 'http://example.com/oembed?url=http%3A%2F%2Fexample.com&format=xml' }

      let(:body) do
        case content
        when Hash
          content.to_xml(root: 'oembed')
        else
          <<-EOS
          <?xml version="1.0" encoding="utf-8" standalone="yes"?>
          <oembed></oembed>
          EOS
        end
      end

      include_examples 'oembed'
    end

    context 'with image response' do
      let(:headers) { { content_type: 'image/jpg', :'content-disposition' => content_disposition } }
      let(:url) { 'http://example.com/image-url.jpg' }
      let(:body) { '' }

      context 'when the content-disposition header contains a valid filename' do
        let(:content_disposition) { 'inline;filename="image-cd.jpg"' }

        it do
          expect(data[:image][:image_url]).to eq(url)
          expect(data[:image][:image_content_type]).to eq('image/jpg')
          expect(data[:image][:image_file_name]).to eq('image-cd.jpg')
        end
      end

      context 'when the content-disposition header does not contain a filename' do
        let(:content_disposition) { 'inline;' }

        it do
          expect(data[:image][:image_url]).to eq(url)
          expect(data[:image][:image_content_type]).to eq('image/jpg')
          expect(data[:image][:image_file_name]).to eq('image-url.jpg')
        end
      end

      context 'when the content-disposition header contains a blank filename' do
        let(:content_disposition) { 'inline;filename=""' }

        it do
          expect(data[:image][:image_url]).to eq(url)
          expect(data[:image][:image_content_type]).to eq('image/jpg')
          expect(data[:image][:image_file_name]).to eq('image-url.jpg')
        end
      end
    end
  end
end
