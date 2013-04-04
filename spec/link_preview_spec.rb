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

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should encode as link' do
        should == {
          :version        => '1.0',
          :provider_name  => %Q{ogp.me},
          :provider_url   => 'http://ogp.me',
          :title          => %Q{Open Graph protocol},
          :description    => %Q{The Open Graph protocol enables any web page to become a rich object in a social graph.},
          :type           => 'link',
          :thumbnail_url  => 'http://ogp.me/logo.png'
        }
      end
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

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should proxy oembed content' do
        should == {
          :version          => '1.0',
          :provider_name    => %Q{YouTube},
          :provider_url     => 'http://www.youtube.com/',
          :url              => "http://youtube.com/watch?v=M3r2XDceM6A",
          :title            => %Q{Amazing Nintendo Facts},
          :description      => %Q{Learn about the history of Nintendo, its gaming systems, and Mario! It's 21 amazing facts about Nintendo you may have never known. Update: As of late 2008, W...},
          :type             => 'video',
          :thumbnail_url    => 'http://i2.ytimg.com/vi/M3r2XDceM6A/hqdefault.jpg',
          :thumbnail_width  => 480,
          :thumbnail_height => 360,
          :html             => %Q{<iframe width="480" height="270" src="http://www.youtube.com/embed/M3r2XDceM6A?feature=oembed" frameborder="0" allowfullscreen></iframe>},
          :width            => 480,
          :height           => 270,
          :author_name      => 'ZackScott',
          :author_url       => 'http://www.youtube.com/user/ZackScott',
        }
      end
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

      it 'should proxy oembed content' do
        should == {
          :version          => '1.0',
          :provider_name    => %Q{SlideRocket},
          :provider_url     => 'http://sliderocket.com/',
          :url              => 'http://app.sliderocket.com/app/fullplayer.aspx?id=f614ec65-0f9b-4167-bb2a-b384dad535f3',
          :title            => %Q{Hoshyar-Foundation},
          :description      => %Q{Proudly crafted with SlideRocket.},
          :thumbnail_url    => 'http://cdn.sliderocket.com/thumbnails/4/43/43b475a4-192e-455e-832f-4a40697d8d25.jpg',
          :type             => 'rich',
          :html             => %Q{<iframe src="http://app.sliderocket.com/app/fullplayer.aspx?id=f614ec65-0f9b-4167-bb2a-b384dad535f3" width="420" height="315" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>},
          :width            => 420,
          :height           => 315
        }
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

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should convert to oembed link' do
        should == {
          :version        => '1.0',
          :provider_name  => %Q{support.apple.com},
          :provider_url   => 'http://support.apple.com',
          :title          => %Q{About the security content of iOS 6.1 Software Update},
          :description    => %Q{This document describes the security content of iOS 6.1.\nFor the protection of our customers, Apple does not disclose, discuss, or confirm security issues until a full investigation has occurred and any necessary patches or releases are available. To learn more about Apple Product Security, see the Apple Product Security website.\nFor information about the Apple Product Security PGP Key, see How to use the Apple Product Security PGP Key.\nWhere possible, CVE IDs are used to reference the vulnerabilities for further information.\nTo learn about other Security Updates, see Apple Security Updates.},
          :type           => 'link'
        }
      end
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

    # FIXME should convert to photo via paperclip
    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should convert to oembed link' do
        should == {
          :version        => '1.0',
          :provider_name  => %Q{www.golden-gate-park.com},
          :provider_url   => 'http://www.golden-gate-park.com',
          :title          => %Q{http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png},
          :type           => 'link',
          :thumbnail_url  => 'http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png'
        }
      end
    end
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

    its(:as_oembed) { should be_nil }
  end

  context 'kaltura opengraph', :vcr => {:cassette_name => 'kaltura_opengraph'} do
    subject(:content) do
      LinkPreview.fetch('https://media.mediaspace.kaltura.com/media/Grim+Outlook+For+BlackBerry/1_vgzs34xc')
    end

    it { should be_a(LinkPreview::Content) }
    its(:url) { should  == 'https://media.mediaspace.kaltura.com/media/Grim+Outlook+For+BlackBerry/1_vgzs34xc' }
    its(:title) { should  == %Q{Grim Outlook For BlackBerry} }
    its(:description) { should == %Q{Summary of business headlines: Research in Motion tops lowered quarterly forecasts but outlook remains grim; Zynga raises $1 billion in IPO; U.S. economy improving, but IMF chief issues warning to all; Wall Street breaks three-day sell-off. Conway G. Gittens reports.} }
    its(:site_name) { should == 'MediaSpace Video Portal' }
    its(:site_url) { should == 'https://media.mediaspace.kaltura.com' }
    its(:image_url) { should == 'https://cdnsecakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/1_vgzs34xc/version/100001/width/' }
    its(:image_data) { should be_a(StringIO) }
    its(:image_content_type) { should == 'image/jpeg' }
    its(:image_file_name) { should == 'width' }

    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('https://media.mediaspace.kaltura.com/media/Grim+Outlook+For+BlackBerry/1_vgzs34xc').ordered.and_call_original
      content.title
      http_client.should_receive(:get).with('https://cdnsecakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/1_vgzs34xc/version/100001/width/').ordered.and_call_original
      content.image_data
      content.description
    end

    # FIXME re-record once Kaltura og:video:width and og:view:height are fixed
    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should convert opengraph to oembed' do
        should == {
          :version        => '1.0',
          :provider_name  => %Q{MediaSpace Video Portal},
          :provider_url   => 'https://media.mediaspace.kaltura.com',
          :title          => %Q{Grim Outlook For BlackBerry},
          :description    => %Q{Summary of business headlines: Research in Motion tops lowered quarterly forecasts but outlook remains grim; Zynga raises $1 billion in IPO; U.S. economy improving, but IMF chief issues warning to all; Wall Street breaks three-day sell-off. Conway G. Gittens reports.},
          :type           => 'video',
          :thumbnail_url  => "https://cdnsecakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/1_vgzs34xc/version/100001/width/",
          :html           => %Q{<iframe width="0" height="0" src="https://www.kaltura.com/index.php/kwidget/wid/_1059491/uiconf_id//entry_id/1_vgzs34xc" frameborder="0" allowfullscreen></iframe>},
          :width          => 0,
          :height         => 0 
        }
      end
    end
  end
end
