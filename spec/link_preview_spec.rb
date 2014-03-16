# encoding: UTF-8

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
    its(:image_url) { should == 'http://i1.ytimg.com/vi/M3r2XDceM6A/hqdefault.jpg' }
    its(:image_data) { should be_a(StringIO) }
    its(:image_content_type) { should == 'image/jpeg' }
    its(:image_file_name) { should == 'hqdefault.jpg' }

    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('http://www.youtube.com/oembed?format=json&url=http%3A%2F%2Fyoutube.com%2Fwatch%3Fv%3DM3r2XDceM6A').ordered.and_call_original
      content.title
      http_client.should_receive(:get).with('http://youtube.com/watch?v=M3r2XDceM6A').ordered.and_call_original
      content.description
      http_client.should_receive(:get).with('http://i1.ytimg.com/vi/M3r2XDceM6A/hqdefault.jpg').ordered.and_call_original
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
          :thumbnail_url    => 'http://i1.ytimg.com/vi/M3r2XDceM6A/hqdefault.jpg',
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
      LinkPreview.fetch('http://videos.kaltura.com/oembed?url=http%3A%2F%2Fvideos.kaltura.com%2Fmedia%2F%2Fid%2F1_abxlxlll&playerId=3073841&entryId=1_abxlxlll', :width => 420)
    end

    it { should be_a(LinkPreview::Content) }
    its(:url) { should  == 'http://videos.kaltura.com/media//id/1_abxlxlll' }
    its(:title) { should  == %Q{KMC Overview | Kaltura KMC Tutorial} }
    its(:description) { should be_nil }
    its(:site_name) { should == 'Kaltura Videos' }
    its(:site_url) { should == 'http://videos.kaltura.com/' }
    its(:image_url) { should == "http://cdnbakmi.kaltura.com/p/811441/sp/81144100/thumbnail/entry_id/1_abxlxlll/version/100012/width//height/" }
    its(:image_data) { should be_a(StringIO) }
    its(:image_content_type) { should == 'image/jpeg' }
    its(:image_file_name) { should == 'height' }

    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('http://videos.kaltura.com/oembed/?url=http%3A%2F%2Fvideos.kaltura.com%2Fmedia%2F%2Fid%2F1_abxlxlll&playerId=3073841&entryId=1_abxlxlll&width=420').ordered.and_call_original
      content.title
      http_client.should_receive(:get).with('http://cdnbakmi.kaltura.com/p/811441/sp/81144100/thumbnail/entry_id/1_abxlxlll/version/100012/width//height/').ordered.and_call_original
      content.image_data
      http_client.should_receive(:get).with('http://videos.kaltura.com/media//id/1_abxlxlll').ordered.and_call_original
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

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }
      it 'should return basic oembed' do
        should == {
          :version       => '1.0',
          :provider_name => 'youtube.com',
          :provider_url  => 'http://youtube.com',
          :title         => 'YouTube',
          :type          => 'link'
        }
      end
    end
  end

  context 'kaltura opengraph', :vcr => {:cassette_name => 'kaltura_opengraph'} do
    subject(:content) do
      LinkPreview.fetch('https://media.mediaspace.kaltura.com/media/Despicable+Me/0_w2zsofdj/6065172')
    end

    it { should be_a(LinkPreview::Content) }
    its(:url) { should  == 'http://media.mediaspace.kaltura.com/media/Despicable+Me/0_w2zsofdj' }
    its(:title) { should  == %Q{Despicable Me} }
    its(:description) { should == %Q{In a happy suburban neighborhood surrounded by white picket fences with flowering rose bushes, sits a black house with a dead lawn. Unbeknownst to the neighbors, hidden beneath this home is a vast secret hideout. Surrounded by a small army of minions, we discover Gru planning the biggest heist in the history of the world. He is going to steal the moon, yes, the moon. Gru delights in all things wicked. Armed with his arsenal of shrink rays, freeze rays, and battle-ready vehicles for land and air, he vanquishes all who stand in his way. Until the day he encounters the immense will of three little orphaned girls who look at him and see something that no one else has ever seen: a potential Dad. The world's greatest villain has just met his greatest challenge: three little girls named Margo, Edith and Agnes.} }
    its(:site_name) { should == 'MediaSpace Demo Site' }
    its(:site_url) { should == 'http://media.mediaspace.kaltura.com' }
    its(:image_url) { should == 'https://cdnbakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/0_w2zsofdj/version/100021/width/400' }
    its(:image_data) { should be_a(StringIO) }
    its(:image_content_type) { should == 'image/jpeg' }
    its(:image_file_name) { should == '400' }

    it 'should issue minimum number of requests' do
      http_client.should_receive(:get).with('https://media.mediaspace.kaltura.com/media/Despicable+Me/0_w2zsofdj/6065172').ordered.and_call_original
      content.title
      http_client.should_receive(:get).with('https://cdnbakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/0_w2zsofdj/version/100021/width/400').ordered.and_call_original
      http_client.should_receive(:get).with('http://cdnbakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/0_w2zsofdj/version/100021/width/400').ordered.and_call_original
      content.image_data
      content.description
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should convert opengraph to oembed' do
        should == {
          :version        => '1.0',
          :provider_name  => %Q{MediaSpace Demo Site},
          :provider_url   => 'http://media.mediaspace.kaltura.com',
          :title          => %Q{Despicable Me},
          :description    => %Q{In a happy suburban neighborhood surrounded by white picket fences with flowering rose bushes, sits a black house with a dead lawn. Unbeknownst to the neighbors, hidden beneath this home is a vast secret hideout. Surrounded by a small army of minions, we discover Gru planning the biggest heist in the history of the world. He is going to steal the moon, yes, the moon. Gru delights in all things wicked. Armed with his arsenal of shrink rays, freeze rays, and battle-ready vehicles for land and air, he vanquishes all who stand in his way. Until the day he encounters the immense will of three little orphaned girls who look at him and see something that no one else has ever seen: a potential Dad. The world's greatest villain has just met his greatest challenge: three little girls named Margo, Edith and Agnes.},
          :type           => 'video',
          :thumbnail_url  => "http://cdnbakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/0_w2zsofdj/version/100021/width/400",
          :html           => %Q{<object width=\"400\" height=\"333\"><param name=\"movie\" value=\"https://www.kaltura.com/index.php/kwidget/wid/_1059491/uiconf_id/16199142/entry_id/0_w2zsofdj\"></param><param name=\"allowScriptAccess\" value=\"always\"></param><param name=\"allowFullScreen\" value=\"true\"></param><embed src=\"https://www.kaltura.com/index.php/kwidget/wid/_1059491/uiconf_id/16199142/entry_id/0_w2zsofdj\" type=\"application/x-shockwave-flash\" allowscriptaccess=\"always\" allowfullscreen=\"true\" width=\"400\" height=\"333\"></embed></object>},
          :width          => 400,
          :height         => 333
        }
      end
    end
  end
end
