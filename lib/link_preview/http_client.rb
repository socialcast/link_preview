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

require 'faraday'
require 'faraday/follow_redirects'

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

  class ForceUTF8Body < Faraday::Middleware
    def force_utf8_body!(env)
      return if env[:body].encoding == Encoding::UTF_8 && env[:body].valid_encoding?
      return unless env[:response_headers][:content_type] =~ /text/
      env[:body].encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      return if env[:body].valid_encoding?
      # cleanse untrusted invalid bytes with a double transcode as suggested here:
      # http://stackoverflow.com/questions/2982677/ruby-1-9-invalid-byte-sequence-in-utf-8
      env[:body].encode!('UTF-16', 'binary', invalid: :replace, undef: :replace, replace: '')
      env[:body].encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    end

    def call(env)
      @app.call(env).on_complete do |response_env|
        force_utf8_body!(response_env)
      end
    end
  end

  class HTTPClient
    def initialize(config)
      @config = config
    end

    def get(uri)
      with_extra_env do
        connection.get(uri).tap do |response|
          response.extend ResponseWithURL
          response.url = uri
        end
      end
    rescue => e
      @config.error_handler.call(e)
      Faraday::Response.new(status: 500)
    end

    def connection
      @connection ||= Faraday.new do |builder|
        builder.options[:timeout] = @config.timeout
        builder.options[:open_timeout] = @config.open_timeout

        builder.use ExtraEnv
        builder.use Faraday::FollowRedirects, limit: @config.max_redirects if @config.follow_redirects
        builder.use NormalizeURI
        builder.use ForceUTF8Body
        @config.middleware.each { |middleware| builder.use middleware }

        builder.use @config.http_adapter
      end
    end

    private

    def with_extra_env(&_block)
      LinkPreview::ExtraEnv.extra = @options
      yield
    ensure
      LinkPreview::ExtraEnv.extra = nil
    end
  end
end
