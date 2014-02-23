require 'spec_helper'

describe LinkPreview::URI do
  describe '.parse' do
    let(:options) { {width: 420} }

    subject(:parsed_uri) do
      LinkPreview::URI.parse(uri, options)
    end

    context 'with parsed LinkPreview::URI' do
      let(:uri) { LinkPreview::URI.parse('http://socialcast.com') }

      it { parsed_uri.should be_a(LinkPreview::URI) }
      it { parsed_uri.to_s.should == 'http://socialcast.com/' }
      it { parsed_uri.should_not be_a_kaltura_uri }
      it { parsed_uri.should_not be_a_oembed_uri }
    end

    context 'with common uri' do
      let(:uri) { 'http://socialcast.com' }

      it { parsed_uri.should be_a(LinkPreview::URI) }
      it { parsed_uri.to_s.should == 'http://socialcast.com/' }
      it { parsed_uri.should_not be_a_kaltura_uri }
      it { parsed_uri.should_not be_a_oembed_uri }
    end

    context 'with kaltura uri' do
      let(:uri) { 'http://demo.kaltura.com/mediaspace/media/index.php/action/oembed?url=http%3A%2F%2Fdemo.kaltura.com%2Fmediaspace%2Fmedia%2F%2Fid%2F1_h9tin5on&playerId=3073841&entryId=1_h9tin5on' }
      it { parsed_uri.should be_a(LinkPreview::URI) }
      it { parsed_uri.to_s.should == 'http://demo.kaltura.com/mediaspace/media/index.php/action/oembed/?url=http%3A%2F%2Fdemo.kaltura.com%2Fmediaspace%2Fmedia%2F%2Fid%2F1_h9tin5on&playerId=3073841&entryId=1_h9tin5on&width=420' }
      it { parsed_uri.should be_a_kaltura_uri }
      it { parsed_uri.should be_a_oembed_uri }
    end

    context 'with kaltura uri with space error' do
      let(:uri) { 'https://cdnsecakmi.kaltura.com/ index.php/kwidget/wid/_1257971/uiconf_id//entry_id/0_aivu6h6k' }
      it { parsed_uri.should be_a(LinkPreview::URI) }
      it { parsed_uri.to_s.should == 'https://cdnsecakmi.kaltura.com/%20index.php/kwidget/wid/_1257971/uiconf_id//entry_id/0_aivu6h6k' }
      it { parsed_uri.should_not be_a_kaltura_uri }
      it { parsed_uri.should_not be_a_oembed_uri }
    end
  end

  describe '#to_absolute' do
    let(:reference_uri) { 'http://socialcast.com' }

    subject(:absolute_uri) do
      LinkPreview::URI.parse(uri).to_absolute(reference_uri)
    end

    context 'with absolute uri ' do
      let(:uri) { 'http://socialcast.com/a/b/c' }

      it { absolute_uri.should be_a(LinkPreview::URI) }
      it { absolute_uri.to_s.should == 'http://socialcast.com/a/b/c' }
    end

    context 'with relative uri' do
      let(:uri) { 'a/b/c' }

      it { absolute_uri.should be_a(LinkPreview::URI) }
      it { absolute_uri.to_s.should == 'http://socialcast.com/a/b/c' }
    end

    context 'with another relative uri' do
      let(:uri) { 'a/b/../../z' }

      it { absolute_uri.should be_a(LinkPreview::URI) }
      it { absolute_uri.to_s.should == 'http://socialcast.com/z' }
    end
  end
end
