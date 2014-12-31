# encoding: UTF-8

# Copyright (c) 2014-2015, VMware, Inc. All Rights Reserved.
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
  describe '#parse_image_file_name' do
    let(:config) { double(LinkPreview::Configuration) }
    let(:parser) { LinkPreview::Parser.new(config) }
    let(:response) do
      Faraday::Response.new.tap do |response|
        allow(response).to receive(:headers).and_return({
          :'content-disposition' => content_disposition
        })

        allow(response).to receive(:url).and_return('http://example.com/image-url.jpg')
      end
    end

    context "when the content-disposition header contains a valid filename" do
      let(:content_disposition) { 'inline;filename="image-cd.jpg"' }
      it 'parses the filename from the header' do
        expect(parser.parse_image_file_name(response)).to eq('image-cd.jpg')
      end
    end
    context "when the content-disposition header does not contain a filename" do
      let(:content_disposition) { 'inline;' }
      it 'parses the filename from the url' do
        expect(parser.parse_image_file_name(response)).to eq('image-url.jpg')
      end
    end
    context "when the content-disposition header contains a blank filename" do
      let(:content_disposition) { 'inline;filename=""' }
      it 'parses the filename from the url' do
        expect(parser.parse_image_file_name(response)).to eq('image-url.jpg')
      end
    end
  end
end
