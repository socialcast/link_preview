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
      return {} unless valid_data?(data)
      case data.headers[:content_type]
      when /image/, 'binary/octet-stream'
        parse_image(data)
      when %r{\Atext/html.*}
        parse_html(data)
      when %r{\Atext/xml.*}
        parse_oembed(data)
      when %r{\Aapplication/json.*}
        parse_oembed(data)
      else
        {}
      end
    end

    def parse_image(data)
      {
        image: {
          image_url: data.url,
          image_data: parse_image_data(data),
          image_content_type: data.headers[:content_type],
          image_file_name: parse_image_file_name(data)
        }
      }
    end

    def parse_image_file_name(data)
      content_disposition_filename = parse_content_disposition_filename(data)
      if content_disposition_filename.present?
        content_disposition_filename
      elsif data.url
        parsed_uri = LinkPreview::URI.parse(data.url, @options)
        parsed_uri.path.split('/').last || parsed_uri.hostname.tr('.', '_')
      end
    end

    private

    def ignore_opengraph_video_type_html?
      @options[:opengraph] && @options[:opengraph].fetch(:ignore_video_type_html, false)
    end

    def valid_data?(data)
      data && data.headers && data.body && data.headers[:content_type]
    end

    def parse_html(data)
      doc = Nokogiri::HTML.parse(data.body, nil, 'UTF-8')
      return unless doc

      enum_oembed_link(doc) do |link_rel|
        discovered_uris << LinkPreview::URI.parse(link_rel, @options)
      end

      {
        opengraph: parse_opengraph_video_data(doc),
        opengraph_embed: parse_opengraph_embed_data(doc),
        html: parse_html_data(doc)
      }
    end

    def parse_html_data(doc)
      {
        title: find_title(doc),
        description: find_meta_description(doc),
        tags: Array.wrap(find_rel_tags(doc))
      }
    end

    # FIXME: currently secure_url is favored over url via implicit ordering of keys
    def parse_opengraph_common_data(doc)
      opengraph_image_array_first_elem = find_meta_property_array(doc, 'og:image').first
      {
        title: find_meta_property(doc, 'og:title'),
        description: find_meta_property(doc, 'og:description'),
        image_secure_url: opengraph_image_array_first_elem['og:image:secure_url'],
        image_url: opengraph_image_array_first_elem['og:image'] || opengraph_image_array_first_elem['og:image:url'],
        tag: find_meta_property(doc, 'og:tag'),
        url: find_meta_property(doc, 'og:url'),
        type: find_meta_property(doc, 'og:type'),
        site_name: find_meta_property(doc, 'og:site_name')
      }
    end

    def parse_opengraph_video_data(doc)
      opengraph_video_array_first_elem = find_meta_property_array(doc, 'og:video').detect { |x| x['og:video:type'] != 'text/html' }
      parse_opengraph_common_data(doc).merge(
        video_secure_url: opengraph_video_array_first_elem['og:video:secure_url'],
        video_url: opengraph_video_array_first_elem['og:video'] || opengraph_video_array_first_elem['og:video:url'],
        video_type: opengraph_video_array_first_elem['og:video:type'],
        video_width: opengraph_video_array_first_elem['og:video:width'],
        video_height: opengraph_video_array_first_elem['og:video:height']
      )
    end

    def parse_opengraph_embed_data(doc)
      return {} if ignore_opengraph_video_type_html?
      opengraph_video_array_first_elem = find_meta_property_array(doc, 'og:video').detect { |x| x['og:video:type'] == 'text/html' }
      opengraph_common_data = parse_opengraph_common_data(doc)
      return {} unless opengraph_video_array_first_elem

      video_secure_url = opengraph_video_array_first_elem['og:video:secure_url']
      video_url = opengraph_video_array_first_elem['og:video:url']
      html_response = parse_video_url_content(video_secure_url) || parse_video_url_content(video_url)
      return {} unless html_response && html_response.body
      opengraph_common_data.merge(
        html: html_response.body,
        video_width: opengraph_video_array_first_elem['og:video:width'],
        video_height: opengraph_video_array_first_elem['og:video:height']
      )
    end

    def parse_oembed(data)
      # TODO: validate oembed response
      { oembed: (parse_oembed_data(data) || {}).merge(url: parse_oembed_content_url(data)) }
    end

    def parse_video_url_content(uri)
      url = LinkPreview::URI.parse(uri, @options)
      @config.http_client.get(url.to_s, @options)
    end

    def parse_oembed_data(data)
      case data.headers[:content_type]
      when /xml/
        Hash.from_xml(Nokogiri::XML.parse(data.body, nil, 'UTF-8').to_s)['oembed']
      when /json/
        MultiJson.load(data.body)
      end
    end

    def parse_oembed_content_url(data)
      return unless data.url
      parsed_uri = LinkPreview::URI.parse(data.url, @options)
      parsed_uri.as_content_uri.to_s
    end

    def parse_image_data(data)
      StringIO.new(data.body.dup) if data.body
    end

    # see http://www.ietf.org/rfc/rfc1806.txt
    def parse_content_disposition_filename(data)
      return unless data.headers[:'content-disposition'] =~ /filename=(.*?)\z/
      Regexp.last_match(1).gsub(/\A['"]+|['"]+\z/, '')
    end

    def enum_oembed_link(doc, &_block)
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
          next unless matching_meta_pair?(node, key, value)
          e.yield OpenStruct.new(key: node.attributes['property'].value, value: node.attributes['content'].value)
        end
      end
    end

    def matching_meta_pair?(node, key, value)
      return false unless valid_meta_node?(node)
      return false unless node.attributes[key]
      return false unless node.attributes[key].value
      return false unless matching_meta_value?(node, key, value)
      true
    end

    def matching_meta_value?(node, key, value)
      case value
      when String
        node.attributes[key].value.casecmp(value.downcase).zero?
      when Regexp
        node.attributes[key].value =~ value
      end
    end

    def valid_meta_node?(node)
      return false unless node
      return false unless node.respond_to?(:attributes)
      return false unless node.attributes['content']
      return false unless node.attributes['content'].value
      true
    end

    def find_meta_description(doc)
      Enumerator.new do |e|
        doc.search('head/meta[name=description]').each do |node|
          next unless matching_meta_pair?(node, 'name', 'description')
          e.yield node.attributes['content'].value
        end
      end.first
    end

    def find_meta_property(doc, property)
      enum_meta_pair(doc, 'property', property).first.try(:value)
    end

    def find_meta_property_array(doc, property)
      [].tap do |property_array|
        property_group = {}
        enum_meta_pair(doc, 'property', /\A#{Regexp.escape(property)}/).each do |pair|
          if property_array_delimiter?(property, pair) && property_group.any?
            property_array.push(property_group.dup)
            property_group.clear
          end
          property_group.merge!(pair.key => pair.value)
        end
        property_array.push(property_group)
      end
    end

    def property_array_delimiter?(property, pair)
      pair.key == property || pair.key == "#{property}:url"
    end
  end
end
