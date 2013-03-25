require 'link_preview'
require 'link_preview/uri'

module LinkPreview
  class Crawler
    def initialize(config, options = {})
      @config = config
      @options = options
      @status = {}
      @queue = Hash.new { |h,k| h[k] = [] }
    end

    # @param [String] URI of content to crawl
    def enqueue!(uri, priority = :default)
      return if full?
      parsed_uri = LinkPreview::URI.parse(uri, @options)

      if oembed_uri = parsed_uri.as_oembed_uri
        enqueue_uri(oembed_uri, :oembed)
      end

      if content_uri = parsed_uri.as_content_uri
        enqueue_uri(content_uri, priority)
      end
    end

    # @return [Hash] latest normalized content discovered by crawling
    def dequeue!(priority_order = [])
      return if finished?
      uri = dequeue_by_priority(priority_order)
      @config.http_client.get(uri).tap do |response|
        @status[uri] = response.status.to_i
      end
    rescue => e
      @status[uri] ||= 500
      @config.error_handler.call(e)
    end

    # @return [Boolean] true if any content discovered thus far has been successfully fetched
    def success?
      @status.any? { |_, status| status == 200 }
    end

    # @return [Boolean] true if all known discovered content has been crawled
    def finished?
      @queue.values.flatten.empty?
    end

    # @return [Boolean] true crawler is at capacity
    def full?
      @queue.values.flatten.size > @config.max_requests
    end

    private

    def dequeue_by_priority(priority_order)
      priority = priority_order.detect { |priority| @queue[priority].any? }
      priority ||= @queue.keys.detect { |priority| @queue[priority].any? }
      @queue[priority].shift
    end

    def enqueue_uri(parsed_uri, priority = :default)
      uri = parsed_uri.to_s
      if !(processed?(uri) || enqueued?(uri))
        @queue[priority] << uri
      end
    end

    def processed?(uri)
      @status.has_key?(uri)
    end

    def enqueued?(uri)
      @queue.values.flatten.uniq.include?(uri)
    end
  end
end
