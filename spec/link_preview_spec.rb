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

describe LinkPreview do
  it { expect(described_class).to be_a(Module) }

  let(:http_client) { LinkPreview.configuration.http_client }

  let(:url) { nil }
  let(:options) { {} }

  subject(:content) do
    LinkPreview.fetch(url, options)
  end

  shared_context 'link_preview' do
    it { should be_a(LinkPreview::Content) }
  end

  context 'open graph data', vcr: { cassette_name: 'ogp.me' } do
    let(:url) { 'http://ogp.me' }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == url }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(Open Graph protocol) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(The Open Graph protocol enables any web page to become a rich object in a social graph.) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'ogp.me' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == url }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'http://ogp.me/logo.png' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/png' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == 'logo.png' }
    end

    it 'should issue minimum number of requests' do
      expect(http_client).to receive(:get).with('http://ogp.me/', {}).ordered.and_call_original
      content.title
      expect(http_client).to receive(:get).with('http://ogp.me/logo.png', {}).ordered.and_call_original
      content.image_data
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should encode as link' do
        should == {
          version: '1.0',
          provider_name: %(ogp.me),
          provider_url: 'http://ogp.me',
          title: %(Open Graph protocol),
          description: %(The Open Graph protocol enables any web page to become a rich object in a social graph.),
          type: 'link',
          thumbnail_url: 'http://ogp.me/logo.png'
        }
      end
    end
  end

  context 'youtube oembed', vcr: { cassette_name: 'youtube' } do
    let(:url) { 'http://youtube.com/watch?v=M3r2XDceM6A' }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == url }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(Amazing Nintendo Facts) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(Learn about the history of Nintendo, its gaming systems, and Mario! It's 21 amazing facts about Nintendo you may have never known. Update: As of late 2008, W...) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'YouTube' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'https://www.youtube.com/' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'https://i.ytimg.com/vi/M3r2XDceM6A/hqdefault.jpg' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/jpeg' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == 'hqdefault.jpg' }
    end

    it 'should issue minimum number of requests' do
      expect(http_client).to receive(:get).with('https://www.youtube.com/oembed?scheme=https&format=json&url=http%3A%2F%2Fyoutube.com%2Fwatch%3Fv%3DM3r2XDceM6A', {}).ordered.and_call_original
      content.title
      expect(http_client).to receive(:get).with('http://youtube.com/watch?v=M3r2XDceM6A', {}).ordered.and_call_original
      content.description
      expect(http_client).to receive(:get).with('https://i.ytimg.com/vi/M3r2XDceM6A/hqdefault.jpg', {}).ordered.and_call_original
      content.image_data
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should proxy oembed content' do
        should == {
          version: '1.0',
          provider_name: %(YouTube),
          provider_url: 'https://www.youtube.com/',
          url: 'http://youtube.com/watch?v=M3r2XDceM6A',
          title: %(Amazing Nintendo Facts),
          description: %(Learn about the history of Nintendo, its gaming systems, and Mario! It's 21 amazing facts about Nintendo you may have never known. Update: As of late 2008, W...),
          type: 'video',
          thumbnail_url: 'https://i.ytimg.com/vi/M3r2XDceM6A/hqdefault.jpg',
          thumbnail_width: 480,
          thumbnail_height: 360,
          html: %(<iframe width="480" height="270" src="https://www.youtube.com/embed/M3r2XDceM6A?feature=oembed" frameborder="0" allowfullscreen></iframe>),
          width: 480,
          height: 270,
          author_name: 'ZackScott',
          author_url: 'https://www.youtube.com/user/ZackScott'
        }
      end
    end
  end

  context 'kaltura oembed', vcr: { cassette_name: 'kaltura' } do
    let(:url) { 'http://videos.kaltura.com/oembed?url=http%3A%2F%2Fvideos.kaltura.com%2Fmedia%2F%2Fid%2F1_abxlxlll&playerId=3073841&entryId=1_abxlxlll' }
    let(:options) { { width: 420 } }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == 'http://videos.kaltura.com/media//id/1_abxlxlll' }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(KMC Overview | Kaltura KMC Tutorial) }
    end

    describe '#description' do
      subject { content.description }
      it { should be_nil }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'Kaltura Videos' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'http://videos.kaltura.com/' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'http://cdnbakmi.kaltura.com/p/811441/sp/81144100/thumbnail/entry_id/1_abxlxlll/version/100012/width//height/' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/jpeg' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == 'height' }
    end

    it 'should issue minimum number of requests' do
      expect(http_client).to receive(:get).with('http://videos.kaltura.com/oembed/?url=http%3A%2F%2Fvideos.kaltura.com%2Fmedia%2F%2Fid%2F1_abxlxlll&playerId=3073841&entryId=1_abxlxlll&width=420', width: 420).ordered.and_call_original
      content.title
      expect(http_client).to receive(:get).with('http://cdnbakmi.kaltura.com/p/811441/sp/81144100/thumbnail/entry_id/1_abxlxlll/version/100012/width//height/', width: 420).ordered.and_call_original
      content.image_data
      expect(http_client).to receive(:get).with('http://videos.kaltura.com/media//id/1_abxlxlll', width: 420).ordered.and_call_original
      content.description
    end
  end

  context 'sliderocket oembed discovery', vcr: { cassette_name: 'sliderocket' } do
    let(:url) { 'http://portal.sliderocket.com/SlideRocket-Presentations/Hoshyar-Foundation' }
    let(:options) { { width: 420 } }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == 'http://portal.sliderocket.com/SlideRocket-Presentations/Hoshyar-Foundation' }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(Hoshyar-Foundation) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(Proudly crafted with SlideRocket.) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'SlideRocket' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'http://sliderocket.com/' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'http://cdn.sliderocket.com/thumbnails/4/43/43b475a4-192e-455e-832f-4a40697d8d25.jpg' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'binary/octet-stream' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == '43b475a4-192e-455e-832f-4a40697d8d25.jpg' }
    end

    it 'should issue minimum number of requests' do
      expect(http_client).to receive(:get).with('http://portal.sliderocket.com/SlideRocket-Presentations/Hoshyar-Foundation', width: 420).ordered.and_call_original
      content.title
      expect(http_client).to receive(:get).with('http://cdn.sliderocket.com/thumbnails/4/43/43b475a4-192e-455e-832f-4a40697d8d25.jpg', width: 420).ordered.and_call_original
      content.image_data
      expect(http_client).to receive(:get).with('http://app.sliderocket.com/app/oEmbed.aspx?url=http%3A%2F%2Fapp.sliderocket.com%2Fapp%2Ffullplayer.aspx%3Fid%3Df614ec65-0f9b-4167-bb2a-b384dad535f3&maxwidth=420', width: 420).ordered.and_call_original
      content.as_oembed
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should proxy oembed content' do
        should == {
          version: '1.0',
          provider_name: %(SlideRocket),
          provider_url: 'http://sliderocket.com/',
          url: 'http://app.sliderocket.com/app/fullplayer.aspx?id=f614ec65-0f9b-4167-bb2a-b384dad535f3',
          title: %(Hoshyar-Foundation),
          description: %(Proudly crafted with SlideRocket.),
          thumbnail_url: 'http://cdn.sliderocket.com/thumbnails/4/43/43b475a4-192e-455e-832f-4a40697d8d25.jpg',
          type: 'rich',
          html: %(<iframe src="http://app.sliderocket.com/app/fullplayer.aspx?id=f614ec65-0f9b-4167-bb2a-b384dad535f3" width="420" height="315" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>),
          width: 420,
          height: 315
        }
      end
    end
  end

  context 'html data with unescaped html', vcr: { cassette_name: 'support.apple.com' } do
    let(:url) { 'http://support.apple.com/kb/HT5642' }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == url }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(About the security content of iOS 6.1 Software Update) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(This document describes the security content of iOS 6.1.\nFor the protection of our customers, Apple does not disclose, discuss, or confirm security issues until a full investigation has occurred and any necessary patches or releases are available. To learn more about Apple Product Security, see the Apple Product Security website.\nFor information about the Apple Product Security PGP Key, see How to use the Apple Product Security PGP Key.\nWhere possible, CVE IDs are used to reference the vulnerabilities for further information.\nTo learn about other Security Updates, see Apple Security Updates.) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'support.apple.com' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'http://support.apple.com' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should be_nil }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_nil }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should be_nil }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should be_nil }
    end

    it 'should issue minimum number of requests' do
      expect(http_client).to receive(:get).with('http://support.apple.com/kb/HT5642', {}).ordered.and_call_original
      content.title
      content.image_data
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should convert to oembed link' do
        should == {
          version: '1.0',
          provider_name: %(support.apple.com),
          provider_url: 'http://support.apple.com',
          title: %(About the security content of iOS 6.1 Software Update),
          description: %(This document describes the security content of iOS 6.1.\nFor the protection of our customers, Apple does not disclose, discuss, or confirm security issues until a full investigation has occurred and any necessary patches or releases are available. To learn more about Apple Product Security, see the Apple Product Security website.\nFor information about the Apple Product Security PGP Key, see How to use the Apple Product Security PGP Key.\nWhere possible, CVE IDs are used to reference the vulnerabilities for further information.\nTo learn about other Security Updates, see Apple Security Updates.),
          type: 'link'
        }
      end
    end
  end

  context 'image data', vcr: { cassette_name: 'ggp.png' } do
    let(:url) { 'http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png' }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == url }
    end

    describe '#title' do
      subject { content.title }
      it { should == 'http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png' }
    end

    describe '#description' do
      subject { content.description }
      it { should be_nil }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'www.golden-gate-park.com' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'http://www.golden-gate-park.com' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/png' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == 'Golden_Gate_Park_Logo_Header.png' }
    end

    # FIXME: should convert to photo via paperclip
    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should convert to oembed link' do
        should == {
          version: '1.0',
          provider_name: %(www.golden-gate-park.com),
          provider_url: 'http://www.golden-gate-park.com',
          title: %(http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png),
          type: 'link',
          thumbnail_url: 'http://www.golden-gate-park.com/wp-content/uploads/2011/02/Golden_Gate_Park_Logo_Header.png'
        }
      end
    end
  end

  context 'youtube oembed 404', vcr: { cassette_name: 'youtube 404' } do
    let(:url) { 'http://youtube.com/watch?v=1' }

    it_behaves_like 'link_preview'
    it { should_not be_found }
    it 'should issue minimum number of requests' do
      expect(http_client).to receive(:get).with('https://www.youtube.com/oembed?scheme=https&format=json&url=http%3A%2F%2Fyoutube.com%2Fwatch%3Fv%3D1', {}).ordered.and_call_original
      expect(http_client).to receive(:get).with('http://youtube.com/watch?v=1', {}).ordered.and_call_original
      content.title
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }
      it 'should return basic oembed' do
        should == {
          version: '1.0',
          provider_name: 'youtube.com',
          provider_url: 'http://youtube.com',
          title: 'YouTube',
          type: 'link'
        }
      end
    end
  end

  context 'kaltura opengraph', vcr: { cassette_name: 'kaltura_opengraph' } do
    let(:url) { 'https://media.mediaspace.kaltura.com/media/Despicable+Me/0_w2zsofdj/6065172' }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == 'http://media.mediaspace.kaltura.com/media/Despicable+Me/0_w2zsofdj' }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(Despicable Me) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(In a happy suburban neighborhood surrounded by white picket fences with flowering rose bushes, sits a black house with a dead lawn. Unbeknownst to the neighbors, hidden beneath this home is a vast secret hideout. Surrounded by a small army of minions, we discover Gru planning the biggest heist in the history of the world. He is going to steal the moon, yes, the moon. Gru delights in all things wicked. Armed with his arsenal of shrink rays, freeze rays, and battle-ready vehicles for land and air, he vanquishes all who stand in his way. Until the day he encounters the immense will of three little orphaned girls who look at him and see something that no one else has ever seen: a potential Dad. The world's greatest villain has just met his greatest challenge: three little girls named Margo, Edith and Agnes.) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'MediaSpace Demo Site' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'http://media.mediaspace.kaltura.com' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'https://cdnbakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/0_w2zsofdj/version/100021/width/400' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/jpeg' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == '400' }
    end

    it 'should issue minimum number of requests' do
      expect(http_client).to receive(:get).with('https://media.mediaspace.kaltura.com/media/Despicable+Me/0_w2zsofdj/6065172', {}).ordered.and_call_original
      content.title
      expect(http_client).to receive(:get).with('https://cdnbakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/0_w2zsofdj/version/100021/width/400', {}).ordered.and_call_original
      content.image_data
      content.description
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should convert opengraph to oembed' do
        should == {
          version: '1.0',
          provider_name: %(MediaSpace Demo Site),
          provider_url: 'http://media.mediaspace.kaltura.com',
          title: %(Despicable Me),
          description: %(In a happy suburban neighborhood surrounded by white picket fences with flowering rose bushes, sits a black house with a dead lawn. Unbeknownst to the neighbors, hidden beneath this home is a vast secret hideout. Surrounded by a small army of minions, we discover Gru planning the biggest heist in the history of the world. He is going to steal the moon, yes, the moon. Gru delights in all things wicked. Armed with his arsenal of shrink rays, freeze rays, and battle-ready vehicles for land and air, he vanquishes all who stand in his way. Until the day he encounters the immense will of three little orphaned girls who look at him and see something that no one else has ever seen: a potential Dad. The world's greatest villain has just met his greatest challenge: three little girls named Margo, Edith and Agnes.),
          type: 'video',
          thumbnail_url: 'https://cdnbakmi.kaltura.com/p/1059491/sp/105949100/thumbnail/entry_id/0_w2zsofdj/version/100021/width/400',
          html: %(<object width=\"400\" height=\"333\"><param name=\"movie\" value=\"https://www.kaltura.com/index.php/kwidget/wid/_1059491/uiconf_id/16199142/entry_id/0_w2zsofdj\"></param><param name=\"allowScriptAccess\" value=\"always\"></param><param name=\"allowFullScreen\" value=\"true\"></param><embed src=\"https://www.kaltura.com/index.php/kwidget/wid/_1059491/uiconf_id/16199142/entry_id/0_w2zsofdj\" type=\"application/x-shockwave-flash\" allowscriptaccess=\"always\" allowfullscreen=\"true\" width=\"400\" height=\"333\"></embed></object>),
          width: 400,
          height: 333
        }
      end
    end
  end

  context 'elasticsearch', vcr: { cassette_name: 'elasticsearch' } do
    let(:url) { 'http://www.elasticsearch.org/overview/hadoop' }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == url }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(Hadoop | Elasticsearch) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(Search your Hadoop Data and Get Real-Time Results Deep API integration makes searching data in Hadoop easy Elasticsearch for Apache Hadoop enables real-time searching against data stored in Apache Hadoop. It provides native integration with Map/Reduce, Hive, Pig, and Cascading, all with no customization. Download Elasticsearch for Apache Hadoop Documentation Great fit for “Big Data” [...]) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'Elasticsearch.org' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should_not be_nil }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'http://www.elasticsearch.org/content/uploads/2013/10/blank_hero.png' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/png' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == 'blank_hero.png' }
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should encode as link' do
        should == {
          version: '1.0',
          provider_name: %(Elasticsearch.org),
          provider_url: 'http://www.elasticsearch.org',
          title: %(Hadoop | Elasticsearch),
          description: %(Search your Hadoop Data and Get Real-Time Results Deep API integration makes searching data in Hadoop easy Elasticsearch for Apache Hadoop enables real-time searching against data stored in Apache Hadoop. It provides native integration with Map/Reduce, Hive, Pig, and Cascading, all with no customization. Download Elasticsearch for Apache Hadoop Documentation Great fit for “Big Data” [...]),
          type: 'link',
          thumbnail_url: 'http://www.elasticsearch.org/content/uploads/2013/10/blank_hero.png'
        }
      end
    end
  end

  context 'resource with bad utf-8 in response', vcr: { cassette_name: 'bad_utf8' } do
    let(:url) { 'http://s.taobao.com' }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == url }
    end

    describe '#title' do
      subject { content.title }
      it { should == url }
    end

    describe '#description' do
      subject { content.description }
      it { should be_nil }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 's.taobao.com' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == url }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should be_nil }
    end
  end

  context 'kaltura with html5 video response fallback', vcr: { cassette_name: 'kaltura_html5_video' } do
    let(:url) { 'http://player.kaltura.com/modules/KalturaSupport/components/share/Share.html' }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == url }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(Kaltura Player: Share Plugin example) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(Kaltura Player: Share plugin demonstrates the ease of which social share can be configured with the kaltura player toolkit.) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'Kaltura' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'http://player.kaltura.com' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'http://cdnbakmi.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/1_sf5ovm7u/version/100003/width/400' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/jpeg' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == '400' }
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should issue minimum number of requests convert opengraph to oembed' do
        expect(http_client).to receive(:get).with('http://player.kaltura.com/modules/KalturaSupport/components/share/Share.html', {}).ordered.and_call_original
        expect(http_client).to receive(:get).with('https://cdnapisec.kaltura.com/p/243342/sp/24334200/embedIframeJs/uiconf_id/28685261/partner_id/243342?iframeembed=true&playerId=kaltura_player&entry_id=1_sf5ovm7u', {}).ordered.and_return(Faraday::Response.new(status: 404))
        expect(http_client).to receive(:get).with('http://cdnbakmi.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/1_sf5ovm7u/version/100003/width/400', {}).ordered.and_call_original
        should == {
          version: '1.0',
          provider_name: %(Kaltura),
          provider_url: 'http://player.kaltura.com',
          title: %(Kaltura Player: Share Plugin example),
          description: %(Kaltura Player: Share plugin demonstrates the ease of which social share can be configured with the kaltura player toolkit.),
          type: 'video',
          thumbnail_url: 'http://cdnbakmi.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/1_sf5ovm7u/version/100003/width/400',
          html: %(<video controls><source src="https://cdnapisec.kaltura.com/p/243342/sp/24334200/playManifest/entryId/1_sf5ovm7u/flavorId/1_d2uwy7vv/format/url/protocol/http/a.mp4" type="video/mp4" /></video>),
          width: 0,
          height: 0
        }
      end
    end
  end

  context 'kaltura with html5 embed response', vcr: { cassette_name: 'kaltura_html5_embed' } do
    let(:url) { 'http://player.kaltura.com/modules/KalturaSupport/components/share/Share.html' }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == url }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(Kaltura Player: Share Plugin example) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(Kaltura Player: Share plugin demonstrates the ease of which social share can be configured with the kaltura player toolkit.) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'Kaltura' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'http://player.kaltura.com' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'http://cdnbakmi.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/1_sf5ovm7u/version/100003/width/400' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/jpeg' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == '400' }
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should issue minimum number of requests convert opengraph to oembed' do
        expect(http_client).to receive(:get).with('http://player.kaltura.com/modules/KalturaSupport/components/share/Share.html', {}).ordered.and_call_original
        expect(http_client).to receive(:get).with('https://cdnapisec.kaltura.com/p/243342/sp/24334200/embedIframeJs/uiconf_id/28685261/partner_id/243342?iframeembed=true&playerId=kaltura_player&entry_id=1_sf5ovm7u', {}).ordered.and_call_original
        expect(http_client).to receive(:get).with('http://cdnbakmi.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/1_sf5ovm7u/version/100003/width/400', {}).ordered.and_call_original
        should == {
          version: '1.0',
          provider_name: %(Kaltura),
          provider_url: 'http://player.kaltura.com',
          title: %(Kaltura Player: Share Plugin example),
          description: %(Kaltura Player: Share plugin demonstrates the ease of which social share can be configured with the kaltura player toolkit.),
          type: 'video',
          thumbnail_url: 'http://cdnbakmi.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/1_sf5ovm7u/version/100003/width/400',
          html: content.sources[:opengraph_embed][:html],
          width: 0,
          height: 0
        }
      end
    end
  end

  context 'kaltura with html5 video response with options {opengraph: { ignore_video_type_html: true } }', vcr: { cassette_name: 'kaltura_html5_ignore_video_type_html', record: :all } do
    let(:url) { 'http://player.kaltura.com/modules/KalturaSupport/components/share/Share.html' }
    let(:options) { { opengraph: { ignore_video_type_html: true } } }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == url }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(Kaltura Player: Share Plugin example) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(Kaltura Player: Share plugin demonstrates the ease of which social share can be configured with the kaltura player toolkit.) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'Kaltura' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'http://player.kaltura.com' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'http://cdnbakmi.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/1_sf5ovm7u/version/100003/width/400' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/jpeg' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == '400' }
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should issue minimum number of requests convert opengraph to oembed' do
        expect(http_client).to receive(:get).with('http://player.kaltura.com/modules/KalturaSupport/components/share/Share.html', opengraph: { ignore_video_type_html: true }).ordered.and_call_original
        expect(http_client).to receive(:get).with('http://cdnbakmi.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/1_sf5ovm7u/version/100003/width/400', opengraph: { ignore_video_type_html: true }).ordered.and_call_original
        should == {
          version: '1.0',
          provider_name: %(Kaltura),
          provider_url: 'http://player.kaltura.com',
          title: %(Kaltura Player: Share Plugin example),
          description: %(Kaltura Player: Share plugin demonstrates the ease of which social share can be configured with the kaltura player toolkit.),
          type: 'video',
          thumbnail_url: 'http://cdnbakmi.kaltura.com/p/243342/sp/24334200/thumbnail/entry_id/1_sf5ovm7u/version/100003/width/400',
          html: %(<video controls><source src="https://cdnapisec.kaltura.com/p/243342/sp/24334200/playManifest/entryId/1_sf5ovm7u/flavorId/1_d2uwy7vv/format/url/protocol/http/a.mp4" type="video/mp4" /></video>),
          width: 0,
          height: 0
        }
      end
    end
  end

  context 'flickr with oembed response', vcr: { cassette_name: 'flickr_oembed' } do
    let(:url) { 'https://www.flickr.com/photos/bees/2341623661' }
    let(:options) { { width: 600 } }

    it_behaves_like 'link_preview'

    describe '#url' do
      subject { content.url }
      it { should == 'https://farm4.staticflickr.com/3123/2341623661_7c99f48bbf_n.jpg' }
    end

    describe '#title' do
      subject { content.title }
      it { should == %(ZB8T0193) }
    end

    describe '#description' do
      subject { content.description }
      it { should == %(Explore bees's photos on Flickr. bees has uploaded 10229 photos to Flickr.) }
    end

    describe '#site_name' do
      subject { content.site_name }
      it { should == 'Flickr' }
    end

    describe '#site_url' do
      subject { content.site_url }
      it { should == 'https://www.flickr.com/' }
    end

    describe '#image_url' do
      subject { content.image_url }
      it { should == 'https://farm4.staticflickr.com/3123/2341623661_7c99f48bbf_q.jpg' }
    end

    describe '#image_data' do
      subject { content.image_data }
      it { should be_a(StringIO) }
    end

    describe '#image_content_type' do
      subject { content.image_content_type }
      it { should == 'image/jpeg' }
    end

    describe '#image_file_name' do
      subject { content.image_file_name }
      it { should == '2341623661_7c99f48bbf_q.jpg' }
    end

    context '#as_oembed' do
      subject(:oembed) { content.as_oembed }

      it 'should convert opengraph to oembed' do
        should == {
          author_name: "\u202e\u202d\u202cbees\u202c",
          author_url: 'https://www.flickr.com/photos/bees/',
          cache_age: 3600,
          description: "Explore bees's photos on Flickr. bees has uploaded 10229 photos to Flickr.",
          flickr_type: 'photo',
          height: 213,
          html: %(<a data-flickr-embed="true" href="https://www.flickr.com/photos/bees/2341623661/" title="ZB8T0193 by \u202e\u202d\u202cbees\u202c, on Flickr"><img src="https://farm4.staticflickr.com/3123/2341623661_7c99f48bbf_n.jpg" width="320" height="213" alt="ZB8T0193"></a><script async src="https://embedr.flickr.com/assets/client-code.js" charset="utf-8"></script>),
          license: 'All Rights Reserved',
          license_id: 0,
          provider_name: 'Flickr',
          provider_url: 'https://www.flickr.com/',
          thumbnail_height: 150,
          thumbnail_url: 'https://farm4.staticflickr.com/3123/2341623661_7c99f48bbf_q.jpg',
          thumbnail_width: 150,
          title: 'ZB8T0193',
          type: 'photo',
          url: 'https://farm4.staticflickr.com/3123/2341623661_7c99f48bbf_n.jpg',
          version: '1.0',
          web_page: 'https://www.flickr.com/photos/bees/2341623661/',
          web_page_short_url: 'https://flic.kr/p/4yVr8K',
          width: '320'
        }
      end
    end
  end
end
