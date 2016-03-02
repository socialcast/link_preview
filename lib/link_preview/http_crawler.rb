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

require 'link_preview'
require 'link_preview/uri'

module LinkPreview
  module ResponseWithURL
    attr_accessor :url
  end

  class HTTPCrawler
    def initialize(config, options = {})
      @config = config
      @options = options
      @status = {}
      @queue = Hash.new { |h, k| h[k] = [] }
    end

    # @param [String] URI of content to crawl
    def enqueue!(uri, priority = :default)
      return if full?
      return unless uri
      parsed_uri = LinkPreview::URI.parse(uri, @options)
      enqueue_uri(parsed_uri.as_oembed_uri, :oembed)
      enqueue_uri(parsed_uri.as_content_uri, priority)
    end

    # @return [Hash] latest normalized content discovered by crawling
    def dequeue!(priority_order = [])
      return if finished?
      uri = dequeue_by_priority(priority_order)
      @config.http_client.get(uri, @options).tap do |response|
        @status[uri] = response.status.to_i
      end
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
      priority = priority_order.detect { |p| @queue[p].any? }
      priority ||= @queue.keys.detect { |p| @queue[p].any? }
      @queue[priority].shift
    end

    def enqueue_uri(parsed_uri, priority = :default)
      return unless parsed_uri
      uri = parsed_uri.to_s
      @queue[priority] << uri unless processed?(uri) || enqueued?(uri)
    end

    def processed?(uri)
      @status.key?(uri)
    end

    def enqueued?(uri)
      @queue.values.flatten.uniq.include?(uri)
    end
  end
end
