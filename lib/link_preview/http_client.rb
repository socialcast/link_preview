# Copyright (c) 2014, VMware, Inc. All Rights Reserved.
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
  class ExtraEnv < Faraday::Middleware
    class << self
      attr_accessor :extra
    end

    def call(env)
      env[:link_preview] = self.class.extra || {}
      @app.call(env)
    ensure
      env[:link_preview] = nil
    end
  end

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

    def faraday_connection
      @faraday_connection ||= Faraday.new do |builder|
        builder.options[:timeout] = @config.timeout
        builder.options[:open_timeout] = @config.open_timeout

        builder.use ExtraEnv
        builder.use Faraday::FollowRedirects, limit: @config.max_redirects if @config.follow_redirects
        builder.use NormalizeURI
        @config.middleware.each { |middleware| builder.use middleware }

        builder.use @config.http_adapter
      end
    end
  end
end
