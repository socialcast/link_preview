require 'uri'
require 'delegate'
require 'oembed'

require 'addressable/uri'
class Addressable::URI
  alias :normalize_without_encoded_query :normalize
  # NOTE hack to correctly escape URI query parameters after normalization
  # see https://github.com/sporkmonger/addressable/issues/50
  def normalize_with_encoded_query
    normalize_without_encoded_query.tap do |uri|
      if uri.query_values.present?
        uri.query_values = uri.query_values.map { |key, value| [key, value] }
      end
      uri
    end
  end
  alias :normalize :normalize_with_encoded_query
end

module LinkPreview
  class URI < SimpleDelegator
    OEmbed::Providers.register_all

    def initialize(addressable_uri, options)
      __setobj__(addressable_uri)
      @options = options
      if kaltura_uri?
        merge_query(kaltura_query)
      elsif oembed_uri?
        merge_query(oembed_query)
      end
    end

    def normalize
      super
      normalize_path
      self
    end

    def as_oembed_uri
      return self if kaltura_uri? || oembed_uri?
      if provider = OEmbed::Providers.find(self.to_s)
        self.class.parse(provider.build(self.to_s), @options)
      end
    end

    def as_content_uri
      return self unless kaltura_uri? || oembed_uri?
      if content_url = self.query_values['url']
        self.class.parse(content_url, @options)
      end
    end

    def to_absolute(reference_uri)
      return self if absolute?
      absolute_uri = self.class.parse(reference_uri, @options)
      absolute_uri.path += self.path
      absolute_uri.normalize
    end

    class << self
      def parse(uri, options = {})
        self.new(Addressable::URI.parse(uri), options).normalize
      end

      def unescape(uri)
        ::URI.unescape(uri)
      end
    end

    private

    def merge_query(query)
      self.query_values ||= {}
      self.query_values = self.query_values.merge(query.stringify_keys).to_a
    end

    def normalize_path
      self.path += '/' if self.path.empty?
      if kaltura_uri?
        self.path += '/' unless self.path =~ %r{/\z}
      end
      self
    end

    def oembed_uri?
      query_values.present? && path =~ /oembed/i && query_values['url']
    end

    def kaltura_uri?
      query_values.present? && query_values['playerId'] && query_values['entryId']
    end

    def oembed_query
      {:maxwidth => @options[:width], :maxheight => @options[:height]}.reject { |_,value| value.nil? }
    end

    def kaltura_query
      {:width => @options[:width], :height => @options[:height]}.reject { |_,value| value.nil? }
    end
  end
end
