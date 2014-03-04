require 'link_preview/configuration'
require 'link_preview/content'

module LinkPreview
  class Client
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= LinkPreview::Configuration.new
    end

    def fetch(uri, options = {}, sources = {})
      LinkPreview::Content.new(configuration, uri, options, sources)
    end

    def load_content(uri, options = {}, sources = {})
      LinkPreview::Content.new(configuration, uri, options.merge(allow_requests: false), sources)
    end
  end

  extend Forwardable
  extend self

  def default_client
    @default_client ||= Client.new
  end

  def_delegators :default_client, :fetch, :load_content, :configure, :configuration
end
