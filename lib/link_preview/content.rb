require 'link_preview/crawler'
require 'link_preview/parser'
require 'link_preview/uri'

require 'active_support/core_ext/object'

class Hash
  # from ryansonnek: utility for performing multiple fetches on hashes
  # ex:
  # h = {:foo => {:bar => :baz}}
  # h.deep_fetch :foo, :bar
  #
  def deep_fetch(*keys)
    last_key = keys.pop
    scope = self
    keys.each do |key|
      scope = scope.fetch key, {}
    end
    scope[last_key]
  end
end

# TODO rename Properties
module LinkPreview
  class Content
    PROPERTIES_TABLE =
      {
        :oembed =>
        {
          :site_name => :provider_name,
          :site_url => :provider_url,
          :image_url => :thumbnail_url
        },
        :opengraph =>
        {
          :image_url => :image
        }
      }

    REVERSE_PROPERTIES_TABLE =
      {}.tap do |reverse_property_table|
        PROPERTIES_TABLE.each do |source, table|
          reverse_property_table[source] = table.invert
        end
      end

    def initialize(config, content_uri, options = {}, properties = {})
      @config = config
      @content_uri = content_uri
      @options = options
      @sources = Hash.new { |h,k| h[k] = {} }
      crawler.enqueue!(@content_uri)

      add_properties!(:initial, properties)
    end

    # @return [String] permalink URL of resource
    def url
      extract(:url) || @content_uri
    end

    PROPERTIES = [:title, :description, :site_name, :site_url, :image_url, :image_data, :image_content_type, :image_file_name]
    PROPERTIES.each do |property|
      define_method(property) do
        extract(property)
      end
    end

    # @return [Boolean] true of at least related content URI has been successfully fetched
    def found?
      extract_all
      crawler.success?
    end

    # @return [Boolean] true of at least one content property is present
    def empty?
      extract_all
      [:initial, :image, :oembed, :opengraph, :html].none? do |source|
        @sources[source].any?(&:present?)
      end
    end

    # FIXME should just be transparent hash
    def raw(*keys)
      unless @sources[keys.first].present?
        properties = parser.parse(crawler.dequeue!([keys.first]))
        add_source_properties!(properties)
      end
      @sources.deep_fetch(*keys)
    end

    def as_oembed
      raw(:oembed).reverse_merge(
        :version         => '1.0',
        :provider_name   => site_name,
        :provider_url    => site_url,
        :title           => title,
        :description     => description,
        :type            => 'link',
        :thumbnail_url   => image_url)
    end

    protected

    def crawler
      @crawler ||= LinkPreview::Crawler.new(@config, @options)
    end

    def parser
      @parser ||= LinkPreview::Parser.new(@config, @options)
    end

    def parsed_url
      LinkPreview::URI.parse(url, @options)
    end

    def default_property(property)
      if respond_to?("default_#{property}")
        send("default_#{property}")
      end
    end

    # called via default_property
    def default_title
      parsed_url.to_s
    end

    # called via default_property
    def default_site_name
      parsed_url.host
    end

    # called via default_property
    def default_site_url
      if parsed_url.scheme && parsed_url.host
        "#{parsed_url.scheme}://#{parsed_url.host}"
      end
    end

    def normalize_property(property, value)
      if respond_to?("normalize_#{property}")
        send("normalize_#{property}", value)
      else
        normalize_generic(property, value)
      end
    end

    def normalize_generic(property, value)
      case value
      when String
        strip_html(value.strip)
      when Array
        value.compact.map { |elem| normalize_property(property, elem ) }
      else
        value
      end
    end

    # called via normalize_property
    def normalize_image_url(partial_image_url)
      return unless partial_image_url
      parsed_partial_image_url = LinkPreview::URI.parse(partial_image_url, @options)
      parsed_absolute_image_url = parsed_partial_image_url.to_absolute(@content_url)
      parsed_absolute_image_url.to_s.tap do |absolute_image_url|
        crawler.enqueue!(absolute_image_url, :image)
      end
    end

    # called via normalize_property
    def normalize_url(discovered_url)
      return unless discovered_url
      unencoded_url = LinkPreview::URI.unescape(discovered_url)
      crawler.enqueue!(unencoded_url, :html)
      unencoded_url
    end

    def get_property(property)
      [:initial, :image, :oembed, :opengraph, :html].map do |source|
        @sources[source][property_alias(source, property)]
      end.compact.first || default_property(property)
    end

    def has_property?(property)
      [:initial, :image, :oembed, :opengraph, :html].map do |source|
        @sources[source][property_alias(source, property)]
      end.any?(&:present?)
    end

    def add_properties!(source, properties)
      properties.symbolize_keys!
      properties.reject!{ |_, value| value.blank? }
      properties.each do |property, value|
        next if @sources[source][property]
        @sources[source][property] = normalize_property(property_unalias(source, property), value)
      end
    end

    def property_alias(source, property)
      PROPERTIES_TABLE.deep_fetch(source, property) || property
    end

    def property_unalias(source, property)
      REVERSE_PROPERTIES_TABLE.deep_fetch(source, property) || property
    end

    def property_source_priority(property)
      case property
      when :description
        [:html, :oembed, :default]
      when :image_data, :image_content_type, :image_file_name
        [:image, :oembed, :default]
      else
        [:oembed, :html, :image, :default]
      end
    end

    def add_source_properties!(properties)
      properties.each do |source, property|
        add_properties!(source, property)
      end
      parser.discovered_uris.each do |uri|
        crawler.enqueue!(uri)
      end
    end

    def extract(property)
      while !crawler.finished? do
        break if has_property?(property)
        data = crawler.dequeue!(property_source_priority(property))
        properties = parser.parse(data)
        add_source_properties!(properties)
      end
      get_property(property)
    end

    def extract_all
      [:title, :description, :image_url, :image_data, :site_name, :site_url].each do |property|
        send(property)
      end
    end

    # FIXME this is expensive
    def strip_html(value)
      Nokogiri::HTML(value).xpath('//text()').remove.to_s
    end
  end
end
