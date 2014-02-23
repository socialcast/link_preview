require 'faraday'
require 'faraday/follow_redirects'

module Faraday
  class Response
    def url
      finished? ? env[:url] : nil
    end
  end
end

module LinkPreview
  class NormalizeURI < Faraday::Middleware
    def call(env)
      env[:url] = env[:url].normalize
      @app.call(env)
    end
  end

  class HTTPClient
    extend Forwardable

    def initialize(config)
      @config = config
    end

    def_delegator :faraday_connection, :get

    private

    # TODO Rails cache middleware
    # TODO redirect validation
    def faraday_connection
      @faraday_connection ||= Faraday.new do |builder|
        builder.use Faraday::FollowRedirects, limit: @config.max_redirects
        builder.use Faraday::Adapter::NetHttp
        builder.options[:timeout] = @config.timeout
        builder.options[:open_timeout] = @config.open_timeout
        builder.use NormalizeURI
      end
    end
  end
end
