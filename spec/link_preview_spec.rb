# encoding: UTF-8
require 'spec_helper'

describe LinkPreview do
  it { should be_a(Module) }

  let(:http_client) { LinkPreview.configuration.http_client }

  context 'open graph data', :vcr => {:cassette_name => 'ogp.me'} do
    subject(:content) do
      LinkPreview.fetch('http://ogp.me')
    end

    it { should be_a(LinkPreview::Content) }
    its(:url) { should  == 'http://ogp.me/' }
    its(:title) { should  == %Q{Open Graph protocol} }
    its(:description) { should == %Q{The Open Graph protocol enables any web page to become a rich object in a social graph.} }
    its(:site_name) { should == 'ogp.me' }
    its(:site_url) { should == 'http://ogp.me' }
    its(:image_url) { should == 'http://ogp.me/logo.png' }
    its(:image_data) { should be_a(StringIO) }
    its(:image_content_type) { should == 'image/png' }
    its(:image_file_name) { should == 'logo.png' }

    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('http://ogp.me/').ordered.and_call_original
      content.title
      http_client.should_receive(:get).with('http://ogp.me/logo.png').ordered.and_call_original
      content.image_data
    end
  end

  context 'youtube oembed', :vcr => {:cassette_name => 'youtube'} do
    subject(:content) do
      LinkPreview.fetch('http://youtube.com/watch?v=M3r2XDceM6A')
    end

    it { should be_a(LinkPreview::Content) }
    its(:url) { should  == 'http://youtube.com/watch?v=M3r2XDceM6A' }
    its(:title) { should  == %Q{Amazing Nintendo Facts} }
    its(:description) { should == %Q{Learn about the history of Nintendo, its gaming systems, and Mario! It's 21 amazing facts about Nintendo you may have never known. Update: As of late 2008, W...} }
    its(:site_name) { should == 'YouTube' }
    its(:site_url) { should == 'http://www.youtube.com/' }
    its(:image_url) { should == 'http://i2.ytimg.com/vi/M3r2XDceM6A/hqdefault.jpg' }
    its(:image_data) { should be_a(StringIO) }
    its(:image_content_type) { should == 'image/jpeg' }
    its(:image_file_name) { should == 'hqdefault.jpg' }

    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('http://www.youtube.com/oembed?format=json&url=http%3A%2F%2Fyoutube.com%2Fwatch%3Fv%3DM3r2XDceM6A').ordered.and_call_original
      content.title
      http_client.should_receive(:get).with('http://youtube.com/watch?v=M3r2XDceM6A').ordered.and_call_original
      content.description
      http_client.should_receive(:get).with('http://i2.ytimg.com/vi/M3r2XDceM6A/hqdefault.jpg').ordered.and_call_original
      content.image_data
    end
  end

  context 'kaltura oembed', :vcr => {:cassette_name => 'kaltura'} do
    subject(:content) do
      LinkPreview.fetch('http://demo.kaltura.com/mediaspace/media/index.php/action/oembed?url=http%3A%2F%2Fdemo.kaltura.com%2Fmediaspace%2Fmedia%2F%2Fid%2F1_h9tin5on&playerId=3073841&entryId=1_h9tin5on', :width => 420)
    end

    it { should be_a(LinkPreview::Content) }
    its(:url) { should  == 'http://demo.kaltura.com/mediaspace/media//id/1_h9tin5on' }
    its(:title) { should  == %Q{The Chronicles of Narnia: The Voyage of the Dawn Treader} }
    its(:description) { should be_nil }
    its(:site_name) { should == 'Kaltura MediaSpace' }
    its(:site_url) { should == 'http://demo.kaltura.com/mediaspace/media/' }
    its(:image_url) { should == 'http://www.kaltura.com/p/439471/thumbnail/width/420/height/285/entry_id/1_h9tin5on' }
    its(:image_data) { should be_a(StringIO) }
    its(:image_content_type) { should == 'image/jpeg' }
    its(:image_file_name) { should == '1_h9tin5on' }

    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('http://demo.kaltura.com/mediaspace/media/index.php/action/oembed/?url=http%3A%2F%2Fdemo.kaltura.com%2Fmediaspace%2Fmedia%2F%2Fid%2F1_h9tin5on&playerId=3073841&entryId=1_h9tin5on&width=420').ordered.and_call_original
      content.title
      http_client.should_receive(:get).with('http://www.kaltura.com/p/439471/thumbnail/width/420/height/285/entry_id/1_h9tin5on').ordered.and_call_original
      content.image_data
      http_client.should_receive(:get).with('http://demo.kaltura.com/mediaspace/media//id/1_h9tin5on').ordered.and_call_original
      content.description
    end
  end

  context 'sliderocket oembed discovery', :vcr => {:cassette_name => 'sliderocket'} do
    subject(:content) do
      LinkPreview.fetch('http://portal.sliderocket.com/SlideRocket-Presentations/Hoshyar-Foundation', :width => 420)
    end

    it { should be_a(LinkPreview::Content) }
    its(:url) { should  == 'http://portal.sliderocket.com/SlideRocket-Presentations/Hoshyar-Foundation' }
    its(:title) { should  == %Q{Hoshyar-Foundation} }
    its(:description) { should == %Q{Proudly crafted with SlideRocket.} }
    its(:site_name) { should == 'SlideRocket' }
    its(:site_url) { should == 'http://sliderocket.com/' }
    its(:image_url) { should == 'http://cdn.sliderocket.com/thumbnails/4/43/43b475a4-192e-455e-832f-4a40697d8d25.jpg' }
    its(:image_data) { should be_a(StringIO) }
    its(:image_content_type) { should == 'binary/octet-stream' }
    its(:image_file_name) { should == '43b475a4-192e-455e-832f-4a40697d8d25.jpg' }

    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('http://portal.sliderocket.com/SlideRocket-Presentations/Hoshyar-Foundation').ordered.and_call_original
      content.title
      http_client.should_receive(:get).with('http://cdn.sliderocket.com/thumbnails/4/43/43b475a4-192e-455e-832f-4a40697d8d25.jpg').ordered.and_call_original
      content.image_data
      http_client.should_receive(:get).with('http://app.sliderocket.com/app/oEmbed.aspx?url=http%3A%2F%2Fapp.sliderocket.com%2Fapp%2Ffullplayer.aspx%3Fid%3Df614ec65-0f9b-4167-bb2a-b384dad535f3&maxwidth=420').ordered.and_call_original
      content.as_oembed
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should' do
        oembed[:type].should == 'rich'
        oembed[:html].should_not be_nil
        oembed[:width].should == 420
      end
    end
  end

  context 'html data with unescaped html', :vcr => {:cassette_name => 'support.apple.com'} do
    subject(:content) do
      LinkPreview.fetch('http://support.apple.com/kb/HT5642')
    end

    it { should be_a(LinkPreview::Content) }
    its(:url) { should  == 'http://support.apple.com/kb/HT5642' }
    its(:title) { should  == %Q{About the security content of iOS 6.1 Software Update} }
    its(:description) { should == %Q{This document describes the security content of iOS 6.1.\nFor the protection of our customers, Apple does not disclose, discuss, or confirm security issues until a full investigation has occurred and any necessary patches or releases are available. To learn more about Apple Product Security, see the Apple Product Security website.\nFor information about the Apple Product Security PGP Key, see How to use the Apple Product Security PGP Key.\nWhere possible, CVE IDs are used to reference the vulnerabilities for further information.\nTo learn about other Security Updates, see Apple Security Updates.} }
    its(:site_name) { should == 'support.apple.com' }
    its(:site_url) { should == 'http://support.apple.com' }
    its(:image_url) { should be_nil }
    its(:image_data) { should be_nil }
    its(:image_content_type) { should be_nil }
    its(:image_file_name) { should be_nil }

    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('http://support.apple.com/kb/HT5642').ordered.and_call_original
      content.title
      content.image_data
    end
  end

  context 'image data', :vcr => {:cassette_name => 'ggp.png'} do
    subject(:content) do
      LinkPreview.fetch('http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png')
    end

    it { should be_a(LinkPreview::Content) }
    its(:url) { should == 'http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png' }
    its(:title) { should == 'http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png' }
    its(:description) { should be_nil }
    its(:site_name) { should == 'www.golden-gate-park.com' }
    its(:site_url) { should == 'http://www.golden-gate-park.com' }
    its(:image_url) { should == 'http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png' }
    its(:image_data) { should be_a(StringIO) }
    its(:image_content_type) { should == 'image/png' }
    its(:image_file_name) { should == 'Golden_Gate_Park_Logo_Header.png' }
  end

  context 'youtube oembed 404', :vcr => {:cassette_name => 'youtube 404'} do
    subject(:content) do
      LinkPreview.fetch('http://youtube.com/watch?v=1')
    end

    it { should_not be_found }
    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('http://www.youtube.com/oembed?format=json&url=http%3A%2F%2Fyoutube.com%2Fwatch%3Fv%3D1').ordered.and_call_original
      http_client.should_receive(:get).with('http://youtube.com/watch?v=1').ordered.and_call_original
      content.title
    end
  end
end
