require 'link_preview/configuration'
require 'link_preview/content'

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
  end

  extend Forwardable
  extend self

  def default_client
    @default_client ||= Client.new
  end

  def_delegators :default_client, :fetch, :configure, :configuration
end
