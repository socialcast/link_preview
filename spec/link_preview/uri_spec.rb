# Copyright (c) 2014, VMware, Inc. All Rights Reserved.
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

describe LinkPreview::URI do
  describe '.parse' do
    let(:options) { {width: 420} }

    subject(:parsed_uri) do
      LinkPreview::URI.parse(uri, options)
    end

    context 'with nil' do
      let(:uri) { nil }
      it { expect(parsed_uri).to be_nil }
    end

    context 'with parsed LinkPreview::URI' do
      let(:uri) { LinkPreview::URI.parse('http://socialcast.com') }

      it { expect(parsed_uri).to be_a(LinkPreview::URI) }
      it { expect(parsed_uri.to_s).to eq('http://socialcast.com/') }
      it { expect(parsed_uri).not_to be_a_kaltura_uri }
      it { expect(parsed_uri).not_to be_a_oembed_uri }
    end

    context 'with common uri' do
      let(:uri) { 'http://socialcast.com' }

      it { expect(parsed_uri).to be_a(LinkPreview::URI) }
      it { expect(parsed_uri.to_s).to eq('http://socialcast.com/') }
      it { expect(parsed_uri).not_to be_a_kaltura_uri }
      it { expect(parsed_uri).not_to be_a_oembed_uri }
    end

    context 'with kaltura uri' do
      let(:uri) { 'http://demo.kaltura.com/mediaspace/media/index.php/action/oembed?url=http%3A%2F%2Fdemo.kaltura.com%2Fmediaspace%2Fmedia%2F%2Fid%2F1_h9tin5on&playerId=3073841&entryId=1_h9tin5on' }
      it { expect(parsed_uri).to be_a(LinkPreview::URI) }
      it { expect(parsed_uri.to_s).to eq('http://demo.kaltura.com/mediaspace/media/index.php/action/oembed/?url=http%3A%2F%2Fdemo.kaltura.com%2Fmediaspace%2Fmedia%2F%2Fid%2F1_h9tin5on&playerId=3073841&entryId=1_h9tin5on&width=420') }
      it { expect(parsed_uri).to be_a_kaltura_uri }
      it { expect(parsed_uri).to be_a_oembed_uri }
    end

    context 'with kaltura uri with space error' do
      let(:uri) { 'https://cdnsecakmi.kaltura.com/ index.php/kwidget/wid/_1257971/uiconf_id//entry_id/0_aivu6h6k' }
      it { expect(parsed_uri).to be_a(LinkPreview::URI) }
      it { expect(parsed_uri.to_s).to eq('https://cdnsecakmi.kaltura.com/%20index.php/kwidget/wid/_1257971/uiconf_id//entry_id/0_aivu6h6k') }
      it { expect(parsed_uri).not_to be_a_kaltura_uri }
      it { expect(parsed_uri).not_to be_a_oembed_uri }
    end
  end

  describe '#to_absolute' do
    let(:reference_uri) { 'http://socialcast.com' }

    subject(:absolute_uri) do
      LinkPreview::URI.parse(uri).to_absolute(reference_uri)
    end

    context 'with absolute uri ' do
      let(:uri) { 'http://socialcast.com/a/b/c' }

      it { expect(absolute_uri).to be_a(LinkPreview::URI) }
      it { expect(absolute_uri.to_s).to eq('http://socialcast.com/a/b/c') }
    end

    context 'with relative uri' do
      let(:uri) { 'a/b/c' }

      it { expect(absolute_uri).to be_a(LinkPreview::URI) }
      it { expect(absolute_uri.to_s).to eq('http://socialcast.com/a/b/c') }
    end

    context 'with another relative uri' do
      let(:uri) { 'a/b/../../z' }

      it { expect(absolute_uri).to be_a(LinkPreview::URI) }
      it { expect(absolute_uri.to_s).to eq('http://socialcast.com/z') }
    end
  end
end
