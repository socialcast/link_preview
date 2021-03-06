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

require 'uri'
require 'delegate'
require 'oembed'

require 'addressable/uri'
module Addressable
  class URI
    alias normalize_without_encoded_query normalize
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
    alias normalize normalize_with_encoded_query
  end
end

module LinkPreview
  class URI < SimpleDelegator
    def initialize(addressable_uri, options)
      super addressable_uri
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
      register_default_oembed_providers!
      return unless oembed_provider
      self.class.parse(oembed_provider.build(to_s), @options)
    end

    def as_content_uri
      return self unless kaltura_uri? || oembed_uri?
      return self unless query_values['url']
      self.class.parse(query_values['url'], @options)
    end

    def to_absolute(reference_uri)
      return self if absolute?
      self.class.parse(::URI.join(reference_uri, path), @options)
    end

    def for_display
      path.sub!(%r{/\z}, '')
      self.path = nil if path.blank?
      self.query = nil if query.blank?
      self.fragment = nil if fragment.blank?
      self
    end

    class << self
      def parse(uri, options = {})
        return unless uri
        new(Addressable::URI.parse(safe_escape(uri)), options).normalize
      end

      def unescape(uri)
        Addressable::URI.unescape(uri, Addressable::URI)
      end

      def escape(uri)
        Addressable::URI.escape(uri, Addressable::URI)
      end

      def safe_escape(uri)
        parsed_uri = Addressable::URI.parse(uri)
        unescaped = unescape(parsed_uri)
        if unescaped.to_s == parsed_uri.to_s
          escape(parsed_uri)
        else
          parsed_uri
        end
      end
    end

    def oembed_uri?
      query_values.present? && path =~ /oembed/i && query_values['url']
    end

    def kaltura_uri?
      query_values.present? && query_values['playerId'] && query_values['entryId']
    end

    private

    def merge_query(query)
      self.query_values ||= {}
      self.query_values = self.query_values.merge(query.stringify_keys).to_a
    end

    def normalize_path
      self.path += '/' if path.empty?
      self.path += '/' if kaltura_uri? && self.path !~ %r{/\z}
    end

    def oembed_query
      { maxwidth: @options[:width], maxheight: @options[:height] }.reject { |_, value| value.nil? }
    end

    def kaltura_query
      { width: @options[:width], height: @options[:height] }.reject { |_, value| value.nil? }
    end

    def register_default_oembed_providers!
      return if OEmbed::Providers.urls.any?
      OEmbed::Providers.register_all
      OEmbed::Providers.register_fallback(OEmbed::ProviderDiscovery)
    end

    def oembed_provider
      @oembed_provider ||= OEmbed::Providers.find(to_s)
    end
  end
end
