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
          :image_url => [:image_secure_url, :image, :image_url],
          :content_url => [:video_secure_url, :video, :video_url],
          :content_type => :video_type,
          :content_width => :width,
          :content_height => :height
        }
      }

    REVERSE_PROPERTIES_TABLE =
      Hash.new { |h,k| h[k] = {} }.tap do |reverse_property_table|
        PROPERTIES_TABLE.each do |source, table|
          table.invert.each_pair do |keys, val|
            Array.wrap(keys).each do |key|
              reverse_property_table[source][key] = val
            end
          end
        end
      end

    def initialize(config, content_uri, options = {}, properties = {})
      @config = config
      @content_uri = content_uri
      @options = options
      @sources = Hash.new { |h,k| h[k] = {} }
      crawler.enqueue!(@content_uri)

      [:initial, :image, :oembed, :opengraph, :html].map do |source|
        next unless properties[source].present?
        add_properties!(source, properties[source])
      end
    end

    # @return [String] permalink URL of resource
    def url
      extract(:url) || @content_uri
    end

    PROPERTIES = [
      :title,
      :description,
      :site_name,
      :site_url,
      :image_url,
      :image_data,
      :image_content_type,
      :image_file_name,
      :content_url,
      :content_type,
      :content_width,
      :content_height ]

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
      if content_type == 'application/x-shockwave-flash'
        raw(:oembed).reverse_merge(as_oembed_video)
      else
        raw(:oembed).reverse_merge(as_oembed_link)
      end
    end

    def content_html
      %Q{<iframe width="#{content_width_scaled}" height="#{content_height_scaled}" src="#{content_url}" frameborder="0" allowfullscreen></iframe>}
    end

    def content_width_scaled
      # Width takes precedence over height
      if @options[:width].to_i > 0
        @options[:width]
      elsif @options[:height].to_i > 0 && content_height.to_i > 0
        # Compute scaled width using the ratio of requested height to actual height, round up to prevent truncation
        (((@options[:height].to_i * 1.0) / (content_height.to_i * 1.0)) * content_width.to_i).ceil
      else
        content_width.to_i
      end
    end

    def content_height_scaled
      # Width takes precedence over height
      if @options[:width].to_i > 0 && content_width.to_i > 0
        # Compute scaled height using the ratio of requested width to actual width, round up to prevent truncation
        (((@options[:width].to_i * 1.0) / (content_width.to_i * 1.0)) * content_height.to_i).ceil
      elsif @options[:height].to_i > 0
        @options[:height]
      else
        content_height.to_i
      end
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
      property_aliases(source,property).detect { |property| @sources[source].has_key?(property) }
    end

    def property_aliases(source, property)
      Array.wrap(PROPERTIES_TABLE.deep_fetch(source, property) || property)
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
      PROPERTIES.each do |property|
        send(property)
      end
    end

    # FIXME this is expensive
    def strip_html(value)
      Nokogiri::HTML(value).xpath('//text()').remove.to_s
    end

    def as_oembed_link
      {
        :version         => '1.0',
        :provider_name   => site_name,
        :provider_url    => site_url,
        :title           => title,
        :description     => description,
        :type            => 'link',
        :thumbnail_url   => image_url
      }
    end

    def as_oembed_video
      as_oembed_link.merge({
          :type            => 'video',
          :html            => content_html,
          :width           => content_width_scaled.to_i,
          :height          => content_height_scaled.to_i})
    end
  end
end
