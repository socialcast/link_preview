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
