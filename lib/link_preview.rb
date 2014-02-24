require 'link_preview/configuration'
require 'link_preview/content'
require 'link_preview/null_crawler'

module LinkPreview
  class Client
    def configure
      yield @configuration
    end

    def configuration
      @configuration ||= LinkPreview::Configuration.new
    end

    def fetch(uri, options = {}, properties = {})
      LinkPreview::Content.new(configuration, uri, options, properties)
    end

    def load_properties(uri, options = {}, properties = {})
      LinkPreview::Content.new(configuration, uri, options, properties).tap do |content|
        content.crawler = LinkPreview::NullCrawler.new(configuration, options)
      end
    end
  end

  extend Forwardable
  extend self

  def default_client
    @default_client ||= Client.new
  end

  def_delegators :default_client, :fetch, :load_properties, :configure, :configuration
end
