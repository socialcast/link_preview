require 'multi_json'
require 'nokogiri'
require 'set'

module LinkPreview
  class Parser
    attr_accessor :discovered_uris

    def initialize(config, options = {})
      @config = config
      @options = options
      self.discovered_uris = Set.new
    end

    def parse(data)
      return {} unless data && data.headers[:content_type] && data.body
      case data.headers[:content_type]
      when /image/, 'binary/octet-stream'
        parse_image(data)
      when %r{\Atext/html.*}
        parse_html(data)
      when %r{\Atext/xml.*}
        parse_oembed(data)
      when %r{\Aapplication/json.*}
        parse_oembed(data)
      end
    end

    def parse_image(data)
      {
        :image => {
          :image_url => data.url,
          :image_data => parse_image_data(data),
          :image_content_type => data.headers[:content_type],
          :image_file_name => parse_image_file_name(data)
        }
      }
    end

    # FIXME currently secure_url is favored over url via implicit ordering of keys
    def parse_html(data)
      if doc = Nokogiri::HTML.parse(data.body, nil, 'UTF-8')
        enum_oembed_link(doc) do |link_rel|
          discovered_uris << LinkPreview::URI.parse(link_rel, @options)
        end
        {
          :opengraph => {
            :title => find_meta_property(doc, 'og:title'),
            :description => find_meta_property(doc, 'og:description'),
            :image_secure_url => find_meta_property(doc, 'og:image:secure_url'),
            :image => find_meta_property(doc, 'og:image'),
            :image_url => find_meta_property(doc, 'og:image:url'),
            :tag => find_meta_property(doc, 'og:tag'),
            :url => find_meta_property(doc, 'og:url'),
            :type => find_meta_property(doc, 'og:type'),
            :site_name => find_meta_property(doc, 'og:site_name'),
            :video_secure_url => find_meta_property(doc, 'og:video:secure_url'),
            :video => find_meta_property(doc, 'og:video'),
            :video_url => find_meta_property(doc, 'og:video:url'),
            :video_type => find_meta_property(doc, 'og:video:type'),
            :video_width => find_meta_property(doc, 'og:video:width'),
            :video_height => find_meta_property(doc, 'og:video:height')
          },
          :html => {
            :title => find_title(doc),
            :description => find_meta_description(doc),
            :tags => Array.wrap(find_rel_tags(doc))
          }
        }
      end
    end

    def parse_oembed(data)
      oembed_data = case data.headers[:content_type]
      when /xml/
        Hash.from_xml(Nokogiri::XML.parse(data.body, nil, 'UTF-8').to_s)['oembed']
      when /json/
        MultiJson.load(data.body)
      end
      # TODO validate oembed response
      { :oembed => (oembed_data || {}).merge(:url => parse_oembed_content_url(data)) }
    end

    def parse_oembed_content_url(data)
      if data.url
        parsed_uri = LinkPreview::URI.parse(data.url, @options)
        parsed_uri.as_content_uri.to_s
      end
    end

    def parse_image_data(data)
      StringIO.new(data.body.dup) if data.body
    end

    def parse_image_file_name(data)
      if filename = parse_content_disposition_filename(data)
        filename
      else
        parsed_uri = LinkPreview::URI.parse(data.url, @options)
        parsed_uri.path.split('/').last || parsed_uri.hostname.gsub('.', '_')
      end
    end

    # see http://www.ietf.org/rfc/rfc1806.txt
    def parse_content_disposition_filename(data)
      if data.headers[:'content-disposition'] =~ /filename=(.*?)\z/
        $1.gsub(/\A['"]+|['"]+\z/, '')
      end
    end

    def enum_oembed_link(doc, &block)
      doc.search("//head/link[@rel='alternate'][@type='application/json+oembed']", "//head/link[@rel='alternate'][@type='text/xml+oembed']").each do |node|
        next unless node && node.respond_to?(:attributes) && node.attributes['href']
        yield node.attributes['href'].value
      end
    end

    def find_title(doc)
      doc.at('head/title').try(:inner_text)
    end

    # See http://microformats.org/wiki/rel-tag
    def find_rel_tags(doc)
      doc.search("//a[@rel='tag']").map(&:inner_text).reject(&:blank?)
    end

    def enum_meta_pair(doc, key, value)
      Enumerator.new do |e|
        doc.search('head/meta').each do |node|
          next unless node
          next unless node.respond_to?(:attributes)
          next unless node.attributes[key]
          next unless node.attributes[key].value
          next unless node.attributes[key].value.downcase == value.downcase
          next unless node.attributes['content']
          next unless node.attributes['content'].value
          e.yield node.attributes['content'].value
        end
      end
    end

    def find_meta_description(doc)
      enum_meta_pair(doc, 'name', 'description').detect(&:present?)
    end

    def find_meta_property(doc, property)
      enum_meta_pair(doc, 'property', property).detect(&:present?)
    end
  end
end
