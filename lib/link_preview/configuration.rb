# Copyright (c) 2014-2015, VMware, Inc. All Rights Reserved.
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

require 'link_preview/http_client'

module LinkPreview
  class Configuration
    attr_accessor :http_client
    attr_accessor :http_adapter
    attr_accessor :follow_redirects
    attr_accessor :max_redirects
    attr_accessor :max_requests
    attr_accessor :timeout
    attr_accessor :open_timeout
    attr_accessor :error_handler
    attr_accessor :middleware

    def http_client
      @http_client ||= HTTPClient.new(self)
    end

    def http_client=(http_client)
      @http_client = http_client
    end

    def http_adapter
      @http_adapter ||= Faraday::Adapter::NetHttp
    end

    def http_adapter=(http_adapter)
      @http_adapter = http_adapter
    end
    def follow_redirects
      @follow_redirects ||= true
    end

    def follow_redirects=(follow_redirects)
      @follow_redirects = follow_redirects
    end

    def max_redirects
      @max_redirects || 3
    end

    def max_requests
      @max_requests || 10
    end

    def timeout
      @timeout || 5 # seconds
    end

    def open_timeout
      @open_timeout || 2 # seconds
    end

    def error_handler
      @error_handler ||= Proc.new() { |_| }
    end

    def middleware
      @middleware || []
    end

    def middleware=(*middleware)
      @middleware = middleware
    end
  end
end
